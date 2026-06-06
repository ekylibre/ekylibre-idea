# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B18 — Formation
    # 3 items × /2, capped at 5.
    class B18 < Base
      INDICATOR = 'B18'
      MAX_SCORE = 5

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(%w[B18_1 B18_2 B18_3], points_per_item: 2)
      end

      def computable?
        %w[B18_1 B18_2 B18_3].any? { |id| item_value_present?(id) }
      end
    end
  end
end
