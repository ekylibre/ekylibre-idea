# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B4 — Limitation des pertes et gaspillages
    # 2 points per checked action (B4_1..B4_9), capped at 6.
    class B4 < Base
      INDICATOR = 'B4'
      MAX_SCORE = 6
      ITEM_IDS = (1..9).map { |i| "B4_#{i}" }.freeze

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(ITEM_IDS, points_per_item: 2)
      end

      def computable?
        ITEM_IDS.any? { |id| item_value_present?(id) }
      end
    end
  end
end
