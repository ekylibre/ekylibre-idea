# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C8 — Transmissibilité économique
    #
    # The PDF doesn't pin a closed-form scoring formula — it says
    # "all values already collected in C1, C3" and "Duke not necessary",
    # leaving the exact aggregation implicit. Until the formula is
    # clarified with the IDEA4 reference, we use a placeholder:
    # ratio of filled items × max score. To be revisited.
    class C8 < Base
      INDICATOR = 'C8'
      MAX_SCORE = 15

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        # Placeholder until the formula is clarified.
        super
      end

      def computable?
        items = Idea::Indicators.items_for(INDICATOR)
        items.any? && items.all? { |it| item_value_present?(it[:id]) }
      end
    end
  end
end
