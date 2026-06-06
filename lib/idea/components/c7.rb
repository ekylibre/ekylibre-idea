# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C7 — Contribution des revenus extérieurs
    #
    # Single boolean item C7_1:
    #   yes → 4
    #   no  → 0
    class C7 < Base
      INDICATOR = 'C7'
      MAX_SCORE = 4

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_truthy?('C7_1') ? 4 : 0
      end

      def computable?
        item_value_present?('C7_1')
      end
    end
  end
end
