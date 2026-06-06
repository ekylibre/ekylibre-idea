# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A16 — Réduction de l'impact sur la qualité de l'eau
    #
    # Item 1 (/2) — N pressure in environment (computed from balance)
    # Item 2 (/3) — Herbicide pressure (A16_45 IFT herbicides thresholds)
    # Item 3 (/2) — Anti-transfer actions (A16_46, A16_47, A16_48)
    # Sum capped at 6.
    class A16 < Base
      INDICATOR = 'A16'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = n_pressure_score
        item_2 = herbicide_pressure_score
        item_3 = boolean_checklist_score(%w[A16_46 A16_47 A16_48], points_per_item: 1)
        (item_1 + item_2 + item_3).clamp(0, MAX_SCORE)
      end

      def computable?
        (1..50).any? { |i| item_value_present?("A16_#{i}") }
      end

      private

        def n_pressure_score
          # Placeholder until the full Pa balance autofill is wired.
          sau = item_numeric('A16_2', default: 0.0)
          return 0 if sau <= 0
          spread = item_numeric('A16_3') + item_numeric('A16_5')
          pressure = spread / sau
          return 2 if pressure < 100
          return 1 if pressure < 170
          0
        end

        def herbicide_pressure_score
          ift = item_numeric('A16_45', default: 0.0)
          return 3 if ift < 1
          return 2 if ift < 2
          return 1 if ift < 4
          0
        end
    end
  end
end
