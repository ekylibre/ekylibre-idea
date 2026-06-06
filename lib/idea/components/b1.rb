# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B1 — Production alimentaire de l'exploitation
    # Item 1 (/6) : ratio production alimentaire / SAU + diversité
    # Item 2 (/3) : production hors-sol consommation humaine (B1_4 bool)
    # Capped at 6.
    class B1 < Base
      INDICATOR = 'B1'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_truthy?('B1_3') ? 3 : 0
        item_2 = item_truthy?('B1_4') ? 3 : 0
        (item_1 + item_2).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[B1_3 B1_4].all? { |id| item_value_present?(id) }
      end
    end
  end
end
