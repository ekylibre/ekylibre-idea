# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A10 — Sobriété dans l'utilisation du phosphore
    #
    # PPHM = (kg P spread) / SAU (ha) — pressure per hectare.
    # Coarse thresholds: low pressure = high score, capped at 8.
    class A10 < Base
      INDICATOR = 'A10'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        sau = item_numeric('A10_3', default: 0.0)
        return 0 if sau <= 0
        # A10_1 = tonnes of mineral P fertilizer ; A10_2 = kg P / tonne
        # → kg P total, divided by SAU (ha) → kg P / ha = PPHM.
        p_spread = item_numeric('A10_1') * item_numeric('A10_2')
        pphm = p_spread / sau
        return 8 if pphm < 5
        return 6 if pphm < 10
        return 4 if pphm < 20
        return 2 if pphm < 40
        0
      end

      def computable?
        %w[A10_1 A10_2 A10_3].all? { |id| item_value_present?(id) }
      end
    end
  end
end
