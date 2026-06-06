# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C5 — Diversification et relations contractuelles
    #
    # Item 1 (/6) — share of biggest client (C5_1):
    #   rank 1 = <33%   → 6
    #   rank 2 = 33-66% → 3
    #   rank 3 = >66%   → 0
    # Item 2 (/6) — contract type for the main production (C5_2):
    #   rank 1 = none           → 0
    #   rank 2 = conventional   → 3
    #   rank 3 = long-term      → 6
    #   rank 4 = AMAP/solidaire → 6
    # Malus (-2) if integrated / "travail à façon" (C5_3 boolean true).
    # Total capped at 10.
    class C5 < Base
      INDICATOR = 'C5'
      MAX_SCORE = 10

      ITEM_1_SCORES = { 1 => 6, 2 => 3, 3 => 0 }.freeze
      ITEM_2_SCORES = { 1 => 0, 2 => 3, 3 => 6, 4 => 6 }.freeze

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        i1 = ITEM_1_SCORES[item_numeric('C5_1').to_i] || 0
        i2 = ITEM_2_SCORES[item_numeric('C5_2').to_i] || 0
        malus = item_truthy?('C5_3') ? -2 : 0
        (i1 + i2 + malus).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[C5_1 C5_2 C5_3].all? { |id| item_value_present?(id) }
      end
    end
  end
end
