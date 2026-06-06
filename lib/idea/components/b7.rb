# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B7 — Services marchands au territoire
    # 3 items at /2 each, capped at 3.
    class B7 < Base
      INDICATOR = 'B7'
      MAX_SCORE = 3

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(%w[B7_1 B7_2 B7_3], points_per_item: 2)
      end

      def computable?
        %w[B7_1 B7_2 B7_3].any? { |id| item_value_present?(id) }
      end
    end
  end
end
