module Idea
  module Components
    class A5 < Base
      INDICATOR = 'A5'

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      # What should Duke ask to the user for this component
      # @returns [DukeResponse] : response
      def duke_redirect
        return Duke::DukeResponse.new if @idea_diagnostic.nil?
        
        Duke::DukeResponse.new
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

      # A5 calculator value
      def a5_1
        # TODO: do it correctly
        1
      end

      # A5 calculator value
      def a5_2
        # TODO: do it correctly
        1
      end

      # A5 calculator value
      def a5_3
        # TODO: do it correctly
        1
      end

      # A5 calculator value
      def a5_4
        # TODO: do it correctly
        1
      end

      # A5 calculator value
      def a5_5
        # TODO: do it correctly
        1
      end

      # A5 calculator value
      def a5_6
        # TODO: do it correctly
        1
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
