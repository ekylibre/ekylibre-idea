module Idea
  module Components
    class A1 < Base
      INDICATOR = 'A1'

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      # Next question the wizard should ask for this component.
      # @returns [Idea::Question]
      def next_question
        return Idea::Question.terminal if @idea_diagnostic.nil? || dominant_sth?

        if item('A1_10').value.nil?
          Idea::Question.new(
            next_indicator: 'A1_10',
            sentence: idea_information_tag(I18n.t('idea.confirm_sth_1',
                                                  sth: sth)) + I18n.t('idea.confirm_sth_2') + idea_information_tag(
                                                    I18n.t('idea.confirm_sth_3')
                                                  ),
            prefilled_value: sth,
            diagnostic_id: @idea_diagnostic.id
          )
        elsif gardening? && item('A1_1').value.nil?
          Idea::Question.new(
            next_indicator: 'A1_01',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif idea_cropset? && item('A1_3').value.nil?
          Idea::Question.new(
            next_indicator: 'A1_03',
            diagnostic_id: @idea_diagnostic.id
          )
        elsif gardening? && item('A1_8').value.nil?
          Idea::Question.new(
            next_indicator: 'A1_08',
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

      #  Resets IdeaDiagnosticItem value & IdeaDiagnosticItemValues values
      def reset_indicator
        @idea_diagnostic_item.update!(value: nil)
        reset_item_values(INDICATOR)
      end

      #  A1_2 calculator value
      def a1_2
        # TODO: do it correctly
        begin
          count = @campaign.activities.distinct.pluck(:cultivation_variety).uniq.select do |var|
            idea_varieties.include?(var.to_sym)
          end.count
        rescue
          0
        end
      end

      #  A1_4 calculator value
      def a1_4
        # TODO: do it correctly
        1
      end

      #  A1_5 calculator value
      def a1_5
        # TODO: do it correctly
        @campaign.net_surface_area.to_d.to_i
      end

      #  A1_6 calculator value
      def a1_6
        # TODO: do it correctly
        areas = Activity.all.map do |act|
          act.net_surface_area(@campaign).to_d
        end
        areas.sort.reverse.take(2).sum.to_i
      end

      #  A1_7 calculator value
      def a1_7
        # TODO: do it correctly
        begin
          count = @campaign.activities.distinct.pluck(:cultivation_variety).uniq.select do |var|
            Onoma::CropSet.find('sheltered_gardening_idea').varieties.include?(var.to_sym)
          end.count
        rescue
          0
        end
      end

      #  A1_9 calculator value
      def a1_9
        # TODO: do it correctly
        1
      end

      #  A1_11 calculator value
      def a1_11
        # TODO: do it correctly
        begin
          @campaign.activities.select{|act| idea_varieties.include? act.cultivation_variety&.to_sym}.map do |act|
            act.net_surface_area(@campaign).to_d
          end.sum.to_i
        rescue
          0
        end
      end

      #  A1_12 calculator value
      def a1_12
        # TODO: do it correctly
        # to_reject = industrial_gardening.split('|')
        # Activity.of_compaign(@campaign).select{|act| sheltered_garning_varieties.include? act.cultivation_variety&.to_sym}
        #                                       .reject{|act| to_reject.include? act.id}
        #                                      .map{|act| act.net_surface_area(@campaign).to_d}
        #                                       .sum
        #                                       .to_i
        1
      end

      private

        # Calculate IdeaDiagnosticItem global score
        def compute_score
          # TODO: set global indicator calcul method
          rand(2..4)
        end

        # Do we have everything we need to calculate a global score (wizard + autofilled)
        def computable?
          dominant_sth? || (autofilled?('a1') && computable_gardening? && computable_idea_cropsets? && !item('A1_10').value.nil?)
        end

        # Is everything gardening related filled ?
        def computable_gardening?
          !gardening? || (!item('A1_8').value.nil? && !item('A1_1').value.nil?)
        end

        # Is everything idea_cropsets related filled ?
        def computable_idea_cropsets?
          !idea_cropset? || !item('A1_3').value.nil?
        end

        # Is the Sth superior than 90% of the rest of the
        def dominant_sth?
          if (sth_percent = item('A1_10').value).present?
            sth_percent.to_i >= 90
          else
            false
          end
        end

    end
  end
end
