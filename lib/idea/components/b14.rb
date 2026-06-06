# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B14 — Contribution à l'emploi et gestion du salariat
    # 3 items × /3, capped at 6.
    class B14 < Base
      INDICATOR = 'B14'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..9).map { |i| "B14_#{i}" }
        boolean_checklist_score(ids, points_per_item: 1)
      end

      def computable?
        (1..9).any? { |i| item_value_present?("B14_#{i}") }
      end
    end
  end
end
