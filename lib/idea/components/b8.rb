# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B8 — Valorisation par circuits courts ou de proximité
    # Item 1 (/2) : vente directe B8_1
    # Item 2 (/3) : proximité géographique B8_2, B8_3
    # Item 3 (/3) : valorisation locale B8_4
    # Capped at 5.
    class B8 < Base
      INDICATOR = 'B8'
      MAX_SCORE = 5

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_truthy?('B8_1') ? 2 : 0
        item_2 = boolean_checklist_score(%w[B8_2 B8_3], points_per_item: 2)
        item_3 = item_truthy?('B8_4') ? 3 : 0
        (item_1 + item_2 + item_3).clamp(0, MAX_SCORE)
      end

      def computable?
        items = Idea::Indicators.items_for(INDICATOR)
        items.any? { |it| item_value_present?(it[:id]) }
      end
    end
  end
end
