# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A19 — Réduction des phytosanitaires & traitements vétérinaires
    #
    # Item 1 (/6) — Phyto reduction: IFT thresholds + practices (A19_2..A19_6)
    # Item 2 (/6) — Veterinary reduction (A19_7..A19_11)
    # Score :
    #   No livestock → item 1
    #   With livestock → min(item 1, item 2)
    class A19 < Base
      INDICATOR = 'A19'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        item_1 = item_1_score
        item_2 = item_2_score
        # No livestock if no veto data
        has_livestock = %w[A19_7 A19_8].any? { |id| item_value_present?(id) }
        if has_livestock
          [item_1, item_2].min.clamp(0, MAX_SCORE)
        else
          item_1.clamp(0, MAX_SCORE)
        end
      end

      def computable?
        (1..11).any? { |i| item_value_present?("A19_#{i}") }
      end

      private

        def item_1_score
          ift = item_numeric('A19_1', default: 0.0)
          ift_score = if ift < 1 then 4
                      elsif ift < 2 then 3
                      elsif ift < 4 then 2
                      elsif ift < 6 then 1
                      else 0
                      end
          alternatives = boolean_checklist_score(%w[A19_3 A19_4 A19_5 A19_6], points_per_item: 1)
          malus = item_truthy?('A19_2') ? -1 : 0
          (ift_score + (alternatives / 2.0).round + malus).clamp(0, MAX_SCORE)
        end

        def item_2_score
          ratio = if item_numeric('A19_8') > 0
                    item_numeric('A19_7') / item_numeric('A19_8')
                  else
                    0.0
                  end
          base = if ratio < 0.5 then 5
                 elsif ratio < 1 then 3
                 elsif ratio < 2 then 1
                 else 0
                 end
          alternatives = item_truthy?('A19_9') ? 1 : 0
          base + alternatives
        end
    end
  end
end
