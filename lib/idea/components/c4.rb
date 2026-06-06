# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C4 — Diversification productive
    #
    # Item 1 (/8) — share of biggest atelier in productive revenue (C4_1):
    #   <50%   → 8
    #   50-75% → 4
    #   75-95% → 2
    #   >95%   → 0
    # Item 2 (/6) — number of products >15% revenue (C4_2):
    #   no product → 6
    #   1 product  → 0
    #   2-3        → 2
    #   >3         → 4
    # Total capped at 10.
    #
    # The wizard stores C4_1 as a level (1..4) and C4_2 as a level (1..4)
    # to dodge the heterogeneous nature of the IDEA categories — the
    # questions in idea_questions.yml ask "more than 95%", "between
    # 75 and 95%", etc. and the value persisted is the chosen rank.
    class C4 < Base
      INDICATOR = 'C4'
      MAX_SCORE = 10

      # Item 1: rank 1 = <50%, 2 = 50-75%, 3 = 75-95%, 4 = >95%
      ITEM_1_SCORES = { 1 => 8, 2 => 4, 3 => 2, 4 => 0 }.freeze
      # Item 2: rank 1 = >3 products, 2 = 2-3, 3 = 1, 4 = none
      ITEM_2_SCORES = { 1 => 4, 2 => 2, 3 => 0, 4 => 6 }.freeze

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        i1 = ITEM_1_SCORES[item_numeric('C4_1').to_i] || 0
        i2 = ITEM_2_SCORES[item_numeric('C4_2').to_i] || 0
        (i1 + i2).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[C4_1 C4_2].all? { |id| item_value_present?(id) }
      end
    end
  end
end
