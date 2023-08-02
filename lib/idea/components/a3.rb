module Idea
  module Components
    class A3 < Base
      INDICATOR = 'A3'

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

      # A3 calculator value
      def a3_1
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_2
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_3
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_4
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_5
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_6
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_7
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_8
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_9
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_10
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_11
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_12
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_13
        # TODO: do it correctly
        1
      end

      # A3 calculator value
      def a3_14
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
