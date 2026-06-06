# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A14 — Protection sanitaire des cultures et animaux
    #
    # Item 1 (/4) — Phyto rotation strategies (A14_1, A14_3 ranks 0/2/4)
    # Item 2 (/4) — Veterinary usage strategies (A14_4, A14_5 booleans)
    # Malus -1 if A14_6 (critical antibiotics) is true.
    # Logic :
    #   No phyto AND no veto         → 4
    #   Plant only                   → item 1
    #   Plant + animal               → min(item 1, item 2)
    class A14 < Base
      INDICATOR = 'A14'
      MAX_SCORE = 4

      ITEM_1_SCORES = { 0 => 0, 1 => 2, 2 => 4 }.freeze

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        phyto = item_truthy?('A14_1')
        veto = item_truthy?('A14_2')
        return MAX_SCORE unless phyto || veto

        item_1 = ITEM_1_SCORES[item_numeric('A14_3').to_i] || 0
        item_2 = boolean_checklist_score(%w[A14_4 A14_5], points_per_item: 2)
        raw = if phyto && veto
                [item_1, item_2].min
              elsif phyto
                item_1
              else
                item_2
              end
        malus = item_truthy?('A14_6') ? -1 : 0
        (raw + malus).clamp(0, MAX_SCORE)
      end

      def computable?
        %w[A14_1 A14_2].any? { |id| item_value_present?(id) }
      end
    end
  end
end
