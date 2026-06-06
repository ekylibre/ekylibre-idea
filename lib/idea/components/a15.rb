# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A15 — Sécuriser la disponibilité des moyens de production
    #
    # Item 1 (/2) — Supplies (A15_1 boolean false = ok → 2)
    # Item 2 (/1) — Forage stock at turn-out (A15_3 / A15_4)
    # Item 3 (/1) — Labor (A15_5 boolean false = ok → 1)
    # Sum capped at 4.
    class A15 < Base
      INDICATOR = 'A15'
      MAX_SCORE = 4

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        # Items are framed as "do you have problems?" — false means OK,
        # so we award points when the user reports no issue.
        item_1 = item_truthy?('A15_1') ? 0 : 2
        item_2 = forage_stock_score
        item_3 = item_truthy?('A15_5') ? 0 : 1
        (item_1 + item_2 + item_3).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[A15_1 A15_5].any? { |id| item_value_present?(id) }
      end

      private

        def forage_stock_score
          ugb = item_numeric('A15_4', default: 0.0)
          return 1 if ugb <= 0  # no livestock — skip the criterion
          months = item_numeric('A15_3') / ugb  # rough proxy
          months >= 4 ? 1 : 0
        end
    end
  end
end
