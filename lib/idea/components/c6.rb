# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C6 — Sensibilité aux aides à la production
    #
    # SA = C6_1 / C6_2 (PAC first-pillar aids / EBE d'IDEA)
    # Score (/6):
    #   SA ≤ 0     → 0
    #   0..25%     → 6
    #   25..50%    → 4
    #   50..100%   → 2
    #   > 100%     → 0
    class C6 < Base
      INDICATOR = 'C6'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ebe = item_numeric('C6_2', default: 0.0)
        return 0 if ebe <= 0
        sa = item_numeric('C6_1') / ebe

        return 0 if sa <= 0
        return 6 if sa <= 0.25
        return 4 if sa <= 0.50
        return 2 if sa <= 1.00
        0
      end

      def computable?
        %w[C6_1 C6_2].all? { |id| item_value_present?(id) }
      end
    end
  end
end
