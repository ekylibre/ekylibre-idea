module Idea
  module Components
    class A2 < Base
      INDICATOR = 'A2'

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      # Next question the wizard should ask for this component.
      # @returns [Idea::Question]
      def next_question
        return Idea::Question.terminal if @idea_diagnostic.nil?

        if item('A2_1').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_01',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif idea_cropset? && item('A2_2').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_02',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif item('A2_27').value.nil? && diagnostic_item_value('A1_10')&.value.nil?
          # A2_27 (meadow surface in hectares) shares its prompt with
          # A1_10 in the legacy flow — answering A1_10 would update A1_10
          # but leave A2_27 nil, so the original code re-asked A1_10 on
          # every reopening of A2. Skip the prompt when A1_10 is already
          # set: the score loses `item_2_6` (which divides A2_17/A2_27)
          # but the rest of A2 stays computable. A1_10 is owned by A1's
          # IdeaDiagnosticItem so we need the cross-item lookup, not
          # the local `item()` scoped to A2.
          Idea::Question.new(
            next_indicator: 'A1_10',
            sentence: idea_information_tag(I18n.t('idea.confirm_sth_1',
                                                  sth: sth)) + I18n.t('idea.confirm_sth_2') + idea_information_tag(
                                                    I18n.t('idea.confirm_sth_3')
                                                  ),
            prefilled_value: sth,
            diagnostic_id: @idea_diagnostic.id
          )
        elsif item('A2_17').value.nil? && item('A2_27').value.present? && item('A2_27').value > 0
          Idea::Question.new(
            next_indicator: 'A2_17',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif gardening? && item('A2_4').value.nil? && diagnostic_item_value('A1_01')&.value.nil?
          # Same shape as the A2_27/A1_10 case above — the prompt writes
          # into A1_01 but the gate checks A2_4, so the original code
          # looped on A1_01 once it had been answered through A1's flow.
          # Skip when A1_01 is already filled; A2_4 stays nil, which
          # leaves computable_gardening? false until A2_4 gets its own
          # input path (out of scope here).
          Idea::Question.new(
            next_indicator: 'A1_01',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif field_industrial_fodder_crops? && item('A2_6').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_06',
            sentence: idea_information_tag(I18n.t('idea.intra_parcel_mix_1',
                                                  variety: main_variety_of('field_industrial_fodder_crops_idea'))) + I18n.t(
                                                    'idea.intra_parcel_mix_2'
                                                  ),
            diagnostic_id: @idea_diagnostic.id
          )
        elsif field_industrial_fodder_crops? && item('A2_7').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_07',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif arboricultural_idea? && item('A2_8').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_08',
            sentence: idea_information_tag(I18n.t('idea.arboricultural_intra_parcel_mix_1',
                                                  variety: main_variety_of('arboricultural_idea'))) + I18n.t('idea.intra_parcel_mix_2'),
            diagnostic_id: @idea_diagnostic.id
          )
        elsif vineyard_idea? && item('A2_13').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_13',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif vineyard_idea? && item('A2_14').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_14',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif gardening? && item('A2_15').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_15',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif animals_idea? && item('A2_18').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_18',
            sentence: idea_information_tag(I18n.t('idea.main_ugb_animal_1', variety: main_ugb_animal)) + I18n.t('idea.main_ugb_animal_2'),
            diagnostic_id: @idea_diagnostic.id
          )
        elsif item('A2_22').value.nil?
          Idea::Question.new(
            next_indicator: 'A2_22',
            diagnostic_id: @idea_diagnostic.id
          )
        else
          Idea::Question.terminal(diagnostic_id: @idea_diagnostic.id)
        end
      end

      # Check if score is calculable & updates it if so
      def update_global_score
        @idea_diagnostic_item.update!(value: compute_score) if computable?
      end

      # Resets IdeaDiagnosticItem value & IdeaDiagnosticItemValues values
      def reset_indicator
        @idea_diagnostic_item.update!(value: nil)
        reset_item_values(INDICATOR)
      end

      # A1_2 calculator value
      def a2_3
        # TODO: do it correctly
        1
      end

      def a2_4
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_5
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_9
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_10
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_11
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_12
        # TODO: do it correctly
        1
      end

      def a2_15
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_16
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_19
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_20
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_21
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_24
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_25
        # TODO: do it correctly
        1
      end

      # A1_2 calculator value
      def a2_28
        # TODO: do it correctly
        1
      end

      private

        def item_1_score
          item('A2_1').value ? 1 : 0
        end

        def item_2_score
          score = item_2_1_score + item_3_score
          score += prorata_area_of('field_industrial_fodder_crops_idea') * item_2_2_score if field_industrial_fodder_crops?
          score += prorata_area_of('vineyard_idea') * item_2_4_score if vineyard_idea?
          score += prorata_area_of('arboricultural_idea') * item_2_3_score if arboricultural_idea?
          score += prorata_area_of('sheltered_gardening_idea') * item_2_5_score if gardening?
        end

        def item_3_score
          score = item('A2_22').value ? 1 : 0
          score += 1 if item('A2_18').value
          score += 1 if item('A2_21').value
          [score, 2].min
        end

        def item_2_1_score
          item('A2_2').value ? 1 : 0
        end

        def item_2_2_score
          score = if item('A2_5').value < 4
                    0
                  elsif item('A2_5').value < 8
                    1
                  else
                    2
                  end
          score += 1 if item('A2_3').value
          score += 2 if item('A2_6').value
          score += 2 if item('A2_7').value
        end

        def item_2_3_score
          score = if item('A2_5').value < 6
                    0
                  elsif item('A2_5').value < 11
                    1
                  else
                    2
                  end
          score += 1 if item('A2_9').value
          score += 2 if item('A2_11').value
        end

        def item_2_4_score
          score = if item('A2_12').value < 4
                    0
                  elsif item('A2_12').value < 8
                    1
                  else
                    2
                  end
          score += 1 if item('A2_13').value
          score += 1 if item('A2_14').value
          [score, 3].min
        end

        def item_2_5_score
          score = [item('A2_15').value, 3].min
          score += 1 if item('A2_16').value
          [score, 3].min
        end

        def item_2_6_score
          sth_g = item('A2_17').value.to_f / item('A2_27').value
          score = if sth_g < 0.5
                    0
                  elsif sth_g < 0.8
                    1
                  elsif sth_g < 0.95
                    2
                  else
                    3
                  end
        end

        # Calculate IdeaDiagnosticItem global score
        def compute_score
          # [(item_1_score + item_2_score + item_3_score), 5].min
          rand(2..4)
        end

        # Do we have everything we need to calculate a global score (wizard + autofilled)
        def computable?
          (autofilled?('a2') && computable_vegetal? && computable_gardening? && computable_field_industrial_fodder_crops? &&
          computable_animal? && computable_arboricultural? && computable_vineyard_idea? && !item('A2_22').value.nil?)
        end

        def computable_vegetal?
          !idea_cropset? || !item('A2_2').value.nil?
        end

        def computable_gardening?
          !gardening? || (!item('A2_4').value.nil? && !item('A2_23').value.nil? && !item('A2_26').value.nil? &&
          !item('A2_15').value.nil?)
        end

        def computable_field_industrial_fodder_crops?
          !field_industrial_fodder_crops? || (!item('A2_6').value.nil? && !item('A2_7').value.nil?)
        end

        def computable_animal?
          !animals_idea? || !item('A2_18').value.nil?
        end

        def computable_arboricultural?
          !arboricultural_idea? || !item('A2_8').value.nil?
        end

        def computable_vineyard_idea?
          !vineyard_idea? || (!item('A2_13').value.nil? && !item('A2_14').value.nil?)
        end

        def main_ugb_animal
          animals_count = Activity.of_family('animal_farming').map do |act|
            [act.name, act.count_during(@campaign)]
          end.to_h
          animals_count.key(animals_count.values.max)
        end

        def main_variety_of(cropset)
          with_size = {}
          Onoma::CropSet.find(cropset).varieties.each do |var|
            begin
              with_size[var] = Activity.of_cultivation_variety(var).sum{|act| act.net_surface_area(@campaign)}.in_hectare
            rescue
              nil
            end
          end
          with_size.key(with_size.values.max)
        end

        def prorata_area_of(cropset)
          total_size = Activity.of_campaign(@campaign).sum{|act| act.net_surface_area(@campaign)}.to_d
          cropset_area = Onoma::CropSet.find(cropset).varieties.map do |var|
            begin
              Activity.of_cultivation_variety(var).sum{|act| act.net_surface_area(@campaign)}.to_d
            rescue
              0.0
            end
          end.sum
          total_size == 0 ? 0 : cropset_area/total_size
        end

        def prorate_sth_area
          item('A2_27').value / Activity.of_campaign(@campaign).sum{|act| act.net_surface_area(@campaign)}.in_hectare.to_d
        end

    end
  end
end
