# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B13 — Réseaux d'innovation et mutualisation
    # 2 items × /2, capped at 3.
    class B13 < Base
      INDICATOR = 'B13'
      MAX_SCORE = 3

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(%w[B13_1 B13_2], points_per_item: 2)
      end

      def computable?
        %w[B13_1 B13_2].any? { |id| item_value_present?(id) }
      end
    end
  end
end
