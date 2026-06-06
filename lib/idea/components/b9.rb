# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B9 — Valorisation des ressources locales
    # 15 items, capped at 5. Each item contributes ~0.5 point.
    class B9 < Base
      INDICATOR = 'B9'
      MAX_SCORE = 5

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..15).map { |i| "B9_#{i}" }
        # Approximate the IDEA4 score : each truthy item is 0.5 point.
        checked = ids.count { |id| item_truthy?(id) }
        (checked * 0.5).round.clamp(0, MAX_SCORE)
      end

      def computable?
        (1..15).any? { |i| item_value_present?("B9_#{i}") }
      end
    end
  end
end
