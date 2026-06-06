# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B20 — Démarche de transparence
    # 3 items × /2, capped at 6.
    class B20 < Base
      INDICATOR = 'B20'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        boolean_checklist_score(%w[B20_1 B20_2 B20_3], points_per_item: 2)
      end

      def computable?
        %w[B20_1 B20_2 B20_3].any? { |id| item_value_present?(id) }
      end
    end
  end
end
