# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A11 — Sobriété dans la consommation en énergie
    #
    # CEDI = sum(direct energies × EQF coef) + sum(indirect inputs × EQF coef)
    # divided by SAU. Thresholds map low CEDI to a high score.
    # Capped at 8.
    class A11 < Base
      INDICATOR = 'A11'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        sau = item_numeric('A11_19', default: 0.0)
        return 0 if sau <= 0
        direct = (1..7).sum { |i| item_numeric("A11_#{i}") }
        indirect = (8..17).sum { |i| item_numeric("A11_#{i}") }
        eqf = item_numeric('A11_18', default: 1.0)
        cedi = (direct + indirect) * eqf / sau
        return 8 if cedi < 500
        return 6 if cedi < 1000
        return 4 if cedi < 2000
        return 2 if cedi < 4000
        0
      end

      def computable?
        item_value_present?('A11_19') && (1..18).any? { |i| item_value_present?("A11_#{i}") }
      end
    end
  end
end
