# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator C11 — Sobriété en intrants
    #
    # SI = C11_2 / C11_1 (input cost / SAU in ha → €/ha)
    # Score (/8):
    #   SI < 400      → 8
    #   400..600      → 6
    #   600..800      → 4
    #   800..1300     → 2
    #   > 1300        → 0
    class C11 < Base
      INDICATOR = 'C11'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        sau = item_numeric('C11_1', default: 0.0)
        return 0 if sau <= 0
        si = item_numeric('C11_2') / sau

        return 8 if si < 400
        return 6 if si < 600
        return 4 if si < 800
        return 2 if si < 1300
        0
      end

      def computable?
        %w[C11_1 C11_2].all? { |id| item_value_present?(id) }
      end
    end
  end
end
