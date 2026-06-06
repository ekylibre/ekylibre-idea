# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C1 — Capacité économique
    #
    # CE = (C1_1 - 0.25*C1_3 - C1_2) / C1_5
    # Item 1 score (/20) from CE / SMIC ratio:
    #   < 0     → 0
    #   0..0.5  → 4
    #   0.5..1  → 8
    #   1..1.5  → 12
    #   1.5..2.5→ 16
    #   ≥ 2.5   → 20
    # Item 2 score = C1_6 (auto-assessment 0..5)
    # Final score = (item1 + item2) capped at 20.
    class C1 < Base
      INDICATOR = 'C1'
      MAX_SCORE = 20

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = score_capacity
        item_2 = item_numeric('C1_6').to_i.clamp(0, 5)
        (item_1 + item_2).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[C1_1 C1_2 C1_3 C1_4 C1_5 C1_6].all? { |id| item_value_present?(id) }
      end

      private

        def score_capacity
          smic = item_numeric('C1_4', default: 0.0)
          uth  = item_numeric('C1_5', default: 0.0)
          return 0 if smic <= 0 || uth <= 0

          capacity = (item_numeric('C1_1') - (0.25 * item_numeric('C1_3')) - item_numeric('C1_2')) / uth
          ratio = capacity / smic

          return 0  if ratio <= 0
          return 4  if ratio < 0.5
          return 8  if ratio < 1
          return 12 if ratio < 1.5
          return 16 if ratio < 2.5
          20
        end
    end
  end
end
