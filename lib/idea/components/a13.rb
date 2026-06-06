# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A13 — Favoriser la fertilité du sol
    #
    # Item 1 (/4) — Long-term soil fertility (A13_1)
    # Item 2 (/4) — Biological quality (A13_4, A13_5, A13_6)
    # Item 3 (/2) — Anti-erosion measures (A13_9)
    # Sum capped at 8.
    class A13 < Base
      INDICATOR = 'A13'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_numeric('A13_1').to_i.clamp(0, 4)  # surface ha-based
        item_2 = boolean_checklist_score(%w[A13_4 A13_5 A13_6], points_per_item: 1)
        item_3 = item_truthy?('A13_9') ? 2 : 0
        (item_1 + item_2 + item_3).clamp(0, MAX_SCORE)
      end

      def computable?
        (1..9).any? { |i| item_value_present?("A13_#{i}") }
      end
    end
  end
end
