module Idea
  module Components
    class Base
      include Duke::Utils::BaseDuke

      # @params [Integer] diagnostic_id : IdeaDiagnostic id
      #  @params [String] indicator : component idea_id
      def initialize(diagnostic_id: nil, idea_name: nil)
        @idea_diagnostic = IdeaDiagnostic.find_by_id(diagnostic_id)
        @idea_diagnostic_item = @idea_diagnostic.idea_diagnostic_items.find_by(idea_id: idea_name)
        @campaign = @idea_diagnostic.campaign
      end

      private

        # @params [String] idea_id: component name
        # Alias for @idea_diagnostic_item_values.find_by_name
        # @return [IdeaDiagnosticItemValue]
        def item(idea_id)
          @idea_diagnostic_item.idea_diagnostic_item_values.find_by(name: idea_id)
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
