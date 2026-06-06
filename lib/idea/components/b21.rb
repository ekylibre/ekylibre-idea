# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B21 — Qualité de vie
    # Single self-assessment 0..6, used directly as the score.
    class B21 < Base
      INDICATOR = 'B21'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_numeric('B21_1').to_i.clamp(0, MAX_SCORE)
      end

      def computable?
        item_value_present?('B21_1')
      end
    end
  end
end
