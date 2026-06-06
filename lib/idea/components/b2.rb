# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B2 — Contribution à l'équilibre alimentaire mondial
    # Item 1 (/6) — taux d'importation de concentrés / B2_2 (élevage)
    # Item 2 (/6) — production de plantes riches en protéines (B2_3)
    # Capped at 6.
    class B2 < Base
      INDICATOR = 'B2'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_truthy?('B2_1') ? 3 : 6
        item_2 = item_truthy?('B2_3') ? 3 : 0
        (item_1 + item_2).clamp(0, MAX_SCORE)
      end

      def computable?
        items = Idea::Indicators.items_for(INDICATOR)
        items.any? && items.all? { |it| item_value_present?(it[:id]) }
      end
    end
  end
end
