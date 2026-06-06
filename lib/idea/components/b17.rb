# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B17 — Accueil, hygiène et sécurité au travail
    # 13 items × ~0.5pt, capped at 5.
    class B17 < Base
      INDICATOR = 'B17'
      MAX_SCORE = 5

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..13).map { |i| "B17_#{i}" }
        checked = ids.count { |id| item_truthy?(id) }
        (checked * 0.5).round.clamp(0, MAX_SCORE)
      end

      def computable?
        (1..13).any? { |i| item_value_present?("B17_#{i}") }
      end
    end
  end
end
