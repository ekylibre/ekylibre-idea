# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A12 — Raisonner l'utilisation de l'eau
    #
    # Item 1 (/4) — Reduce water needs (4 sub-items)
    # Item 2 (/4) — Saving strategies (3 sub-items)
    # Item 3 (/1) — Bonus rainwater recovery
    # Sum capped at 8.
    class A12 < Base
      INDICATOR = 'A12'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = boolean_checklist_score(%w[A12_4 A12_5 A12_9 A12_13], points_per_item: 1)
        item_2 = boolean_checklist_score(%w[A12_6 A12_7 A12_8 A12_10 A12_11], points_per_item: 1)
        item_3 = item_truthy?('A12_12') ? 1 : 0
        (item_1 + item_2 + item_3).clamp(0, MAX_SCORE)
      end

      def computable?
        (1..13).any? { |i| item_value_present?("A12_#{i}") }
      end
    end
  end
end
