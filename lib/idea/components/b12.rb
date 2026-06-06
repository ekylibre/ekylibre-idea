# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B12 — Gestion des déchets non organiques
    # Item 1 (/3): 8 boolean items B12_1..B12_8, score = #truthy >= 4 -> 3, >= 2 -> 2, >= 1 -> 1
    # Item 2 (/1): bonus emballage réutilisable B12_9
    # Capped at 3.
    class B12 < Base
      INDICATOR = 'B12'
      MAX_SCORE = 3

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        checked = (1..8).count { |i| item_truthy?("B12_#{i}") }
        item_1 = if checked >= 4 then 3
                 elsif checked >= 2 then 2
                 elsif checked >= 1 then 1
                 else 0
                 end
        item_2 = item_truthy?('B12_9') ? 1 : 0
        (item_1 + item_2).clamp(0, MAX_SCORE)
      end

      def computable?
        (1..10).any? { |i| item_value_present?("B12_#{i}") }
      end
    end
  end
end
