# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B19 — Implication sociale territoriale et solidarités
    # 6 items × /1, capped at 6.
    class B19 < Base
      INDICATOR = 'B19'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..6).map { |i| "B19_#{i}" }
        boolean_checklist_score(ids, points_per_item: 1)
      end

      def computable?
        (1..6).any? { |i| item_value_present?("B19_#{i}") }
      end
    end
  end
end
