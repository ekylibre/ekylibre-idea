# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B22 — Isolement
    # 2 items × /3, capped at 6.
    class B22 < Base
      INDICATOR = 'B22'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(%w[B22_1 B22_2], points_per_item: 3)
      end

      def computable?
        %w[B22_1 B22_2].any? { |id| item_value_present?(id) }
      end
    end
  end
end
