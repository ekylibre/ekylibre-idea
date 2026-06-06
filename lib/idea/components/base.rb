module Idea
  module Components
    class Base
      include Idea::SentenceHelpers

      # @params [Integer] diagnostic_id : IdeaDiagnostic id
      #  @params [String] indicator : component idea_id
      def initialize(diagnostic_id: nil, idea_name: nil)
        @idea_diagnostic = IdeaDiagnostic.find_by_id(diagnostic_id)
        @idea_diagnostic_item = @idea_diagnostic.idea_diagnostic_items.find_by(idea_id: idea_name)
        @campaign = @idea_diagnostic.campaign
      end

      # Generic wizard contract — walks the indicator's items in YAML
      # order and returns the first wizard item whose IdeaDiagnosticItemValue
      # is still nil. Subclasses with a scripted flow (A1, A2, A4) override
      # this; the 48 stubs and the autofill-only indicators (A3, A5, A7,
      # A8, A10, B21, …) get a working questionnaire for free.
      def next_question
        return Idea::Question.terminal if @idea_diagnostic.nil?
        return Idea::Question.terminal(diagnostic_id: @idea_diagnostic.id) unless self.class.const_defined?(:INDICATOR)

        Idea::Indicators.items_for(self.class::INDICATOR).each do |descriptor|
          next unless descriptor[:source] == 'wizard'
          row = item(descriptor[:id])
          next if row.nil? || !row.value.nil?
          return Idea::Question.new(
            next_indicator: descriptor[:id],
            diagnostic_id: @idea_diagnostic.id
          )
        end

        Idea::Question.terminal(diagnostic_id: @idea_diagnostic.id)
      end

      # Score recompute hook called from the controller after every
      # answer. Writes nil safely when the indicator isn't yet computable.
      def update_global_score
        return unless @idea_diagnostic_item
        score = computable? ? compute_score : nil
        @idea_diagnostic_item.update!(value: score) if score != @idea_diagnostic_item.value
      end

      # Wipes everything for this indicator and lets the autofill job
      # repopulate. Generic implementation driven by the YAML inventory.
      def reset_indicator
        @idea_diagnostic_item.update!(value: nil)
        reset_item_values(self.class::INDICATOR) if self.class.const_defined?(:INDICATOR)
      end

      # Generic scoring — "ratio × treshold" rounded to an integer.
      # Returns nil when the indicator is not yet computable.
      # Placeholder formula until each indicator's IDEA4 PDF spec is
      # implemented in a dedicated sprint.
      def compute_score
        return nil unless self.class.const_defined?(:INDICATOR)
        items = Idea::Indicators.items_for(self.class::INDICATOR)
        return nil if items.empty?
        treshold = (Idea::Indicators.treshold_for(self.class::INDICATOR) || 5).to_f
        filled = items.count { |descriptor| item_value_present?(descriptor[:id]) }
        ratio = filled.to_f / items.size
        (ratio * treshold).round
      end

      # @return [Boolean] true once every wizard item has been answered.
      # Pure autofill indicators (no wizard item) are computable as soon
      # as a single autofill row has a value — otherwise the score would
      # never appear until somebody answers a non-existent question.
      def computable?
        return false unless self.class.const_defined?(:INDICATOR)
        items = Idea::Indicators.items_for(self.class::INDICATOR)
        return false if items.empty?
        wizard_ids = items.select { |i| i[:source] == 'wizard' }.map { |i| i[:id] }
        if wizard_ids.empty?
          items.any? { |descriptor| item_value_present?(descriptor[:id]) }
        else
          wizard_ids.all? { |id| item_value_present?(id) }
        end
      end

      private

        # @params [String] idea_id: component name
        # Alias for @idea_diagnostic_item_values.find_by_name
        # @return [IdeaDiagnosticItemValue]
        def item(idea_id)
          @idea_diagnostic_item.idea_diagnostic_item_values.find_by(name: idea_id)
        end

        # Truthy when the item_value exists and carries a non-nil value
        # in its nature-typed column. Used by the generic compute_score
        # and computable? in lieu of `item(id)&.value&.present?` (which
        # treats `false` as "absent" — wrong for boolean answers).
        def item_value_present?(idea_id)
          row = item(idea_id)
          return false if row.nil?
          !row.value.nil?
        end

        # Float view of an item_value, used by the Dimension C indicators
        # (and any future numeric-formula indicator). Defaults to 0.0
        # when missing so divisions and sums don't blow up on an
        # uncomputable indicator. Callers that need to distinguish "not
        # set yet" from "set to zero" should use item_value_present?
        # in computable? before calling this.
        def item_numeric(idea_id, default: 0.0)
          row = item(idea_id)
          return default if row.nil? || row.value.nil?
          row.value.to_f
        end

        # Boolean view: a missing or nil value yields false. Used in
        # binary-scoring indicators (C7, C9 sub-items).
        def item_truthy?(idea_id)
          row = item(idea_id)
          return false if row.nil? || row.value.nil?
          row.value == true || row.value.to_s == 'true'
        end

        # "Check-list" scoring pattern shared by most Dimension B
        # indicators (B4 "2 points par action", B5/B6/B12/… "1 point par
        # case cochée"). Counts how many items in `ids` are truthy, then
        # multiplies by `points_per_item` and caps at the indicator's
        # treshold.
        def boolean_checklist_score(ids, points_per_item: 1)
          checked = ids.count { |id| item_truthy?(id) }
          total = checked * points_per_item
          treshold = (Idea::Indicators.treshold_for(self.class::INDICATOR) || total).to_i
          [total, treshold].min
        end

        # "Rank" pattern used in B2, B9, etc. Looks up the integer answer
        # in a `{rank => points}` map and falls back to 0 when unknown.
        def rank_score(idea_id, ranks)
          ranks[item_numeric(idea_id).to_i] || 0
        end

        # Same lookup but scoped to the whole diagnostic, not just the
        # current component's item. Use when one indicator's
        # next_question needs to read an item_value owned by another
        # indicator (e.g. A2 checking whether A1_10 has been answered).
        # @return [IdeaDiagnosticItemValue, nil]
        def diagnostic_item_value(name)
          IdeaDiagnosticItemValue
            .joins(:idea_diagnostic_item)
            .where(idea_diagnostic_items: { idea_diagnostic_id: @idea_diagnostic.id })
            .find_by(name: name)
        end

        # @params [String] idea_id: component name
        # Sets to nil all idea_diagnostic_item_values for an indicator
        def reset_item_values(idea_name)
          (1..Idea::Indicators.item_values_count(idea_name)).each do |num|
            item("#{idea_name}_#{num}").set!(nil, :string)
          end
        end

        # @params [String] idea_name: component name downcased
        # @returns [Array] list of all item_values that can be autofilled
        def autofillables(idea_name)
          self.methods.select{|method| method.match("#{idea_name}_")}
        end

        # @params [String] idea_name: component name downcased
        # Ensures all autofillables item_values have values
        def autofilled?(idea_name)
          autofillables(idea_name).none? do |item_value|
            item(item_value.upcase).value.nil?
          end
        end

        # @returns [Array]: list of all idea varieties
        def idea_varieties
          %w[field_industrial_fodder_crops_idea vineyard_idea arboricultural_idea].map do |cgi|
            Onoma::CropSet.find(cgi).varieties
          end.flatten
        end

        # Do we have any gardening on this farm for this campaign ?
        def gardening?
          Activity.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('sheltered_gardening_idea').varieties).any?
        end

        #  Do we have any idea_crop on this farm for this campaign ?
        def idea_cropset?
          Activity.of_campaign(@campaign).of_cultivation_varieties(idea_varieties).any?
        end

        def field_industrial_fodder_crops?
          Activity.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('field_industrial_fodder_crops_idea').varieties).any?
        end

        def animals_idea?
          Activity.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('animals_idea').varieties).any?
        end

        def vineyard_idea?
          Activity.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('vineyard_idea').varieties).any?
        end

        def arboricultural_idea?
          Activity.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('arboricultural_idea').varieties).any?
        end

        def sau(unit = :hectare)
          @campaign.net_surface_area.in(unit).to_f.round(2)
        end

        def sth
          # Look for all meadow reference name for campaign in activity productions
          aps = ActivityProduction.of_campaign(@campaign).where(reference_name: %w[meadow])
          if aps.present?
            aps.pluck(:size_value).compact.sum.round(2).to_f
          else
            0.0
          end
        end

        def fallow_area
          aps = ActivityProduction.of_campaign(@campaign).where(usage: %w[fallow_land], support_nature: 'cultivation')
          if aps.present?
            aps.pluck(:size_value).compact.sum.round(2).to_f
          else
            0.0
          end
        end

        def grass_borders(unit = :hectare)
          a_grass_borders = CapLandParcel.of_campaign(@campaign).where(main_crop_code: %w[BFS BOR BTA])
          if a_grass_borders.present?
            total = a_grass_borders.geom_union(:shape).area
            total.in_square_meter.convert(unit).to_f.round(4)
          else
            0.0
          end
        end

        def agroforest_cap_land_parcel
          # TODO
          nil
        end

        def edges_total_length
          buffer = 0.7
          geometries = CultivableZone.all.map{ |cz| cz.shape }.compact.uniq
          edges = RegisteredAreaItem.of_nature(:edge).buffer_intersecting(buffer, *geometries)
          if edges.present?
            total = 0.0
            edges.each do |edge|
              total += edge.geometry.to_rgeo.length
            end
            total.round(2).in_meter.to_f
          else
            0.0
          end
        end

        def aligned_trees_perimeter
          p_trees = CapNeutralArea.of_campaign(@campaign).where(nature: %w[V2])
          if p_trees.present?
            p_trees.perimeters(:shape).to_f
          else
            0.0
          end
        end

        def settlements_perimeter
          p_settlements = CapNeutralArea.of_campaign(@campaign).where(nature: %w[A4 A5 A7])
          if p_settlements.present?
            p_settlements.perimeters(:shape).to_f
          else
            0.0
          end
        end

        def alone_trees_count
          CapNeutralArea.of_campaign(@campaign).where(nature: %w[V1]).count
        end

        def boskets_area(unit = :hectare)
          a_boskets = CapNeutralArea.of_campaign(@campaign).where(nature: %w[V3])
          if a_boskets.present?
            total = a_boskets.geom_union(:shape).area
            total.in_square_meter.convert(unit).to_f.round(4)
          else
            0.0
          end
        end

        def ponds_perimeter
          p_ponds = CapNeutralArea.of_campaign(@campaign).where(nature: %w[A1])
          if p_ponds.present?
            p_ponds.perimeters(:shape).to_f
          else
            0.0
          end
        end

    end
  end
end
