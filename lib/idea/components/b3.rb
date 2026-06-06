# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B3 — Démarche de qualité de la production alimentaire
    # Item 1 (/4) : qualité origine et/ou process (B3_1, B3_2, B3_4)
    # Item 2 (/2) : qualité nutritionnelle (B3_5)
    # Capped at 6.
    class B3 < Base
      INDICATOR = 'B3'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = boolean_checklist_score(%w[B3_1 B3_2 B3_4], points_per_item: 2)
        item_2 = item_truthy?('B3_5') ? 2 : 0
        (item_1 + item_2).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[B3_1 B3_2 B3_4 B3_5].all? { |id| item_value_present?(id) }
      end
    end
  end
end
