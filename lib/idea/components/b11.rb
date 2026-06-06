# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B11 — Accessibilité de l'espace
    # Item 1 (/2) zone rurale B11_1, B11_2
    # Item 2 (/3) zone urbaine/périurbaine
    # Item 3 (/1) bonus
    # Capped at 3.
    class B11 < Base
      INDICATOR = 'B11'
      MAX_SCORE = 3

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..4).map { |i| "B11_#{i}" }
        boolean_checklist_score(ids, points_per_item: 1)
      end

      def computable?
        (1..4).any? { |i| item_value_present?("B11_#{i}") }
      end
    end
  end
end
