# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A6 — Autonomie en énergie, matériaux, matériels, semences et plants
    #
    # Item 1 (/3) — Autonomie en énergie (A6_1)
    # Item 2 (/3) — Autonomie matériaux/matériels (A6_2, A6_3, A6_4)
    # Item 3 (/3) — Autonomie semences et plants (A6_5, A6_8, A6_10)
    #   weighted by crop surface (A6_6, A6_9, A6_11)
    # Total capped at 8.
    class A6 < Base
      INDICATOR = 'A6'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_truthy?('A6_1') ? 3 : 0
        item_2 = boolean_checklist_score(%w[A6_2 A6_3 A6_4], points_per_item: 1)
        item_3 = boolean_checklist_score(%w[A6_5 A6_8 A6_10], points_per_item: 1)
        (item_1 + item_2 + item_3).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[A6_1 A6_2 A6_3 A6_4 A6_5 A6_8 A6_10].any? { |id| item_value_present?(id) }
      end
    end
  end
end
