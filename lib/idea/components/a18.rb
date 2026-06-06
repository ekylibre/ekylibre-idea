# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator A18 — Changement climatique
    #
    # Emissions nettes de GES = sum(GHG sources) - sum(carbon storage)
    # Thresholds /6 from low net emissions to high.
    # Major sources: direct energies, indirect inputs, livestock (CH4),
    # nitrogen fertilization (N2O).
    # Storage: hedges, agroforestry, permanent grassland.
    class A18 < Base
      INDICATOR = 'A18'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        # Coarse approximation until the full LCA is wired.
        emitters = boolean_checklist_score(%w[A18_1 A18_2 A18_3], points_per_item: -1)
        # Negative weights for actual emitter quantities are tricky in
        # boolean_checklist_score (it caps at treshold); use storage
        # signals as positive contributions instead.
        storage = boolean_checklist_score(%w[A18_19 A18_20 A18_21 A18_22], points_per_item: 1)
        ([0, storage].max + emitters).clamp(0, MAX_SCORE)
      end

      def computable?
        (1..26).any? { |i| item_value_present?("A18_#{i}") }
      end
    end
  end
end
