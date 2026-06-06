# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B10 — Patrimoine
    # 4 items each /1, capped at 3.
    class B10 < Base
      INDICATOR = 'B10'
      MAX_SCORE = 3

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..8).map { |i| "B10_#{i}" }
        boolean_checklist_score(ids, points_per_item: 1)
      end

      def computable?
        (1..8).any? { |i| item_value_present?("B10_#{i}") }
      end
    end
  end
end
