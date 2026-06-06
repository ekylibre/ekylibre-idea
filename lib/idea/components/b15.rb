# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B15 — Mutualisation du travail
    # 5 boolean items, 2 points each, capped at 6.
    class B15 < Base
      INDICATOR = 'B15'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..5).map { |i| "B15_#{i}" }
        boolean_checklist_score(ids, points_per_item: 2)
      end

      def computable?
        (1..5).any? { |i| item_value_present?("B15_#{i}") }
      end
    end
  end
end
