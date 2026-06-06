# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C2 — Capacité de remboursement
    #
    # PdD = (C2_1 + C2_2) / C2_3
    # Score (/12) from debt-weight ratio:
    #   PdD < 0    → 0
    #   PdD < 30%  → 12
    #   30..45%    → 8
    #   45..60%    → 4
    #   ≥ 60%      → 0
    class C2 < Base
      INDICATOR = 'C2'
      MAX_SCORE = 12

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ebe = item_numeric('C2_3', default: 0.0)
        return 0 if ebe <= 0

        pdd = (item_numeric('C2_1') + item_numeric('C2_2')) / ebe

        return 0  if pdd < 0
        return 12 if pdd < 0.30
        return 8  if pdd < 0.45
        return 4  if pdd < 0.60
        0
      end

      def computable?
        %w[C2_1 C2_2 C2_3].all? { |id| item_value_present?(id) }
      end
    end
  end
end
