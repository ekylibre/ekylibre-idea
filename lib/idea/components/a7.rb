# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A7 — Autonomie alimentaire de l'élevage
    #
    # Item 1 — Autonomie en fourrages AUT_F = A7_2 / (A7_1 + A7_2) → /8 thresholds
    # Item 2 — Autonomie en concentrés AUT_AC = A7_4 / (A7_3 + A7_4) → /8 thresholds
    # Score :
    #   no livestock (A7_5 rank 0)         → 0
    #   monogastric (A7_5 rank 1)          → item 2
    #   herbivore   (A7_5 rank 2)          → round(0.7*item1 + 0.3*item2)
    class A7 < Base
      INDICATOR = 'A7'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        rank = item_numeric('A7_5').to_i
        return 0 if rank.zero?

        item_1 = autonomy_score('A7_1', 'A7_2')
        item_2 = autonomy_score('A7_3', 'A7_4')

        case rank
        when 1 then item_2.clamp(0, MAX_SCORE)
          # Monogastric: only concentrates matter.
        when 2 then ((0.7 * item_1) + (0.3 * item_2)).round.clamp(0, MAX_SCORE)
          # Herbivore: forages weighted 70%, concentrates 30%.
        else item_2.clamp(0, MAX_SCORE)
        end
      end

      def computable?
        item_value_present?('A7_5') && %w[A7_1 A7_2 A7_3 A7_4].any? { |id| item_value_present?(id) }
      end

      private

        def autonomy_score(purchased_id, consumed_id)
          purchased = item_numeric(purchased_id)
          consumed = item_numeric(consumed_id)
          total = purchased + consumed
          return 0 if total <= 0
          ratio = consumed / total
          return 0 if ratio < 0.5
          return 2 if ratio < 0.7
          return 4 if ratio < 0.85
          return 6 if ratio < 0.95
          8
        end
    end
  end
end
