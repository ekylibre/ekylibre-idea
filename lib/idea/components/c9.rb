# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C9 — Pérennité probable
    #
    # Item 1 (/4) — existence in 10 years (C9_1):
    #   rank 1 = quasi-certain    → 4
    #   rank 2 = probable         → 3
    #   rank 3 = souhaitée        → 1
    #   rank 4 = disparition      → 0
    # Item 2 (/2) — secured land access (C9_2 boolean):
    #   yes → 2 ; no → 0
    # Item 3 (/1) — future projects (C9_3 boolean):
    #   yes → 1 ; no → 0
    # Item 4 (/2) — parcel structure quality (C9_4):
    #   rank 1 = good   → 2
    #   rank 2 = normal → 1
    #   rank 3 = hard   → 0
    # Total capped at 8.
    class C9 < Base
      INDICATOR = 'C9'
      MAX_SCORE = 8

      ITEM_1_SCORES = { 1 => 4, 2 => 3, 3 => 1, 4 => 0 }.freeze
      ITEM_4_SCORES = { 1 => 2, 2 => 1, 3 => 0 }.freeze

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        i1 = ITEM_1_SCORES[item_numeric('C9_1').to_i] || 0
        i2 = item_truthy?('C9_2') ? 2 : 0
        i3 = item_truthy?('C9_3') ? 1 : 0
        i4 = ITEM_4_SCORES[item_numeric('C9_4').to_i] || 0
        (i1 + i2 + i3 + i4).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[C9_1 C9_2 C9_3 C9_4].all? { |id| item_value_present?(id) }
      end
    end
  end
end
