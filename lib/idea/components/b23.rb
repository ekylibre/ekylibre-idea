# frozen_string_literal: true

module Idea
  module Components
    # IDEA4 indicator B23 — Bien-être animal
    # 34 items; complex conditional scoring (with/without livestock).
    # Placeholder: count of truthy items / 6, capped at 6.
    # To be refined when the IDEA4 § B23 livestock matrix is fully
    # implemented in a dedicated sprint.
    class B23 < Base
      INDICATOR = 'B23'
      MAX_SCORE = 6

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      def compute_score
        return nil unless computable?
        ids = (1..34).map { |i| "B23_#{i}" }
        checked = ids.count { |id| item_truthy?(id) }
        (checked / 6.0).round.clamp(0, MAX_SCORE)
      end

      def computable?
        (1..34).any? { |i| item_value_present?("B23_#{i}") }
      end
    end
  end
end
