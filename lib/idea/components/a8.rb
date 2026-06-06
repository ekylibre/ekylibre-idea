# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A8 — Autonomie en azote
    #
    # AUT_N = 1 - (N épandu importé) / (N épandu total + N fixé)
    # Score thresholds (/8):
    #   AUT_N < 20%      → 0
    #   20..40%          → 2
    #   40..60%          → 4
    #   60..80%          → 6
    #   ≥ 80%            → 8
    #
    # Items A8_1..A8_12 carry the components of the nitrogen balance.
    # Placeholder until the autofill connects each to its accountancy/
    # ferti record. For now: A8_imported_n + A8_total_n + A8_fixed_n are
    # expected to be summarized into named item_values (or stay nil and
    # the indicator is not computable).
    class A8 < Base
      INDICATOR = 'A8'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        imported = item_numeric('A8_1') + item_numeric('A8_5')  # mineral + organic purchased
        total = item_numeric('A8_7') + item_numeric('A8_8')     # mineral + organic spread
        fixed = item_numeric('A8_9') * item_numeric('A8_11')    # legume fraction × fixation coef
        denom = total + fixed
        return 0 if denom <= 0

        autn = 1.0 - (imported / denom)
        return 0 if autn < 0.2
        return 2 if autn < 0.4
        return 4 if autn < 0.6
        return 6 if autn < 0.8
        8
      end

      def computable?
        # Need at least one nitrogen flow to be meaningful.
        %w[A8_1 A8_5 A8_7 A8_8].any? { |id| item_value_present?(id) }
      end
    end
  end
end
