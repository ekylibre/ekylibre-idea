# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C10 — Efficience brute du processus productif
    #
    # EB = (C10_1 + C10_2 + C10_3 - C10_4 - C10_5) / (C10_1 + C10_2 + C10_3 - C10_4)
    # Score (/12):
    #   EB < 0.1   → 0
    #   0.1..0.2   → 2
    #   0.2..0.3   → 4
    #   0.3..0.4   → 6
    #   0.4..0.5   → 8
    #   0.5..0.6   → 10
    #   ≥ 0.6      → 12
    class C10 < Base
      INDICATOR = 'C10'
      MAX_SCORE = 12

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        production = item_numeric('C10_1') + item_numeric('C10_2') + item_numeric('C10_3') - item_numeric('C10_4')
        return 0 if production <= 0

        eb = (production - item_numeric('C10_5')) / production

        return 0  if eb < 0.1
        return 2  if eb < 0.2
        return 4  if eb < 0.3
        return 6  if eb < 0.4
        return 8  if eb < 0.5
        return 10 if eb < 0.6
        12
      end

      def computable?
        %w[C10_1 C10_2 C10_3 C10_4 C10_5].all? { |id| item_value_present?(id) }
      end
    end
  end
end
