# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C3 — Endettement structurel
    #
    # TES = C3_1 / (C3_1 + C3_2 + C3_3)
    # Score (/6):
    #   TES < 30%   → 6
    #   30..60%     → 3
    #   ≥ 60%       → 0
    class C3 < Base
      INDICATOR = 'C3'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        denom = item_numeric('C3_1') + item_numeric('C3_2') + item_numeric('C3_3')
        return 0 if denom <= 0

        tes = item_numeric('C3_1') / denom
        return 6 if tes < 0.30
        return 3 if tes < 0.60
        0
      end

      def computable?
        %w[C3_1 C3_2 C3_3].all? { |id| item_value_present?(id) }
      end
    end
  end
end
