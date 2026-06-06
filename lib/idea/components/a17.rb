# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A17 — Qualité de l'air
    #
    # Item 1 (/2) — Engine emissions (EPE) thresholds
    # Item 2 (/2) — Practices reducing particles & NH3 (3 sub-items)
    # Item 3 (/3) — Anti-drift equipment (A17_4, A17_5)
    # Malus item 4 (/-1) — emissive practices (A17_11)
    # Sum capped at 6.
    class A17 < Base
      INDICATOR = 'A17'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        epe = item_numeric('A17_1', default: 0.0)
        item_1 = if epe < 2 then 2
                 elsif epe < 4 then 1
                 else 0
                 end
        item_2 = boolean_checklist_score(%w[A17_6 A17_7 A17_8], points_per_item: 1)
        item_3 = boolean_checklist_score(%w[A17_4 A17_5], points_per_item: 1)
        malus = item_truthy?('A17_11') ? -1 : 0
        (item_1 + item_2 + item_3 + malus).clamp(0, MAX_SCORE)
      end

      def computable?
        (1..11).any? { |i| item_value_present?("A17_#{i}") }
      end
    end
  end
end
