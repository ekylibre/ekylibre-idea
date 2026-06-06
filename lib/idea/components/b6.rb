# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B6 — Engagement dans des démarches environnementales
    # Capped at 5.
    class B6 < Base
      INDICATOR = 'B6'
      MAX_SCORE = 5

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_truthy?('B6_1') ? 5 : 0
        item_2 = item_truthy?('B6_2') ? 3 : 0
        (item_1 + item_2).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[B6_1 B6_2].any? { |id| item_value_present?(id) }
      end
    end
  end
end
