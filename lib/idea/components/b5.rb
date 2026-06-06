# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B5 — Liens sociaux, hédoniques et culturels à l'alimentation
    # 3 items, each /3, summed capped at 6.
    class B5 < Base
      INDICATOR = 'B5'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(%w[B5_1 B5_2 B5_3], points_per_item: 3)
      end

      def computable?
        %w[B5_1 B5_2 B5_3].any? { |id| item_value_present?(id) }
      end
    end
  end
end
