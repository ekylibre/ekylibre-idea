module Idea
  module Components
    class A4 < Base
      INDICATOR = 'A4'

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      # What should Duke ask to the user for this component
      # @returns [DukeResponse] : response
      def duke_redirect
        return Duke::DukeResponse.new if @idea_diagnostic.nil?

        if item('A4_10').value.nil?
          Duke::DukeResponse.new(
            redirect: 'A4_10',
            sentence: duke_information_tag(I18n.t('idea.confirm_fallow_land_1', fallow_area: fallow_area)) + I18n.t('idea.confirm_fallow_land_2'),
            parsed: @idea_diagnostic.id,
            options: fallow_area
          )
        else
          Duke::DukeResponse.new
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

      private

        # Calculate IdeaDiagnosticItem global score
        def compute_score
          # TODO: set global indicator calcul method
          rand(2..4)
        end

        def computable?
          true
        end

    end
  end
end
