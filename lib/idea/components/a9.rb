# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A9 — Sobriété dans l'usage de l'eau et partage de la ressource
    #
    # Placeholder formula based on volume and ZRE flag.
    # A9_1 (wizard) — origine prélèvement
    # A9_2 (autofill) — ZRE (boolean)
    # A9_3 (wizard) — quantité totale prélevée
    #
    # Capped at 8. Until IDEA4 thresholds are clarified, count truthy
    # signals as a coarse approximation.
    class A9 < Base
      INDICATOR = 'A9'
      MAX_SCORE = 8

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        # Lower volume = better autonomy. Coarse buckets while the
        # real IDEA4 thresholds are not yet wired.
        volume = item_numeric('A9_3', default: nil.to_f)
        sensitive = item_truthy?('A9_2')
        score = case volume
                when 0..500 then 8
                when 500..2000 then 6
                when 2000..5000 then 4
                when 5000..10_000 then 2
                else 0
                end
        score -= 2 if sensitive  # penalty when drawing on a stressed area
        score.clamp(0, MAX_SCORE)
      end

      def computable?
        item_value_present?('A9_3')
      end
    end
  end
end
