# frozen_string_literal: true

module Idea
  # Question contract returned by Idea::Components::*#next_question.
  #
  # Carries everything the wizard needs for one round-trip: which
  # item_value the user must answer next (next_indicator), the human-facing
  # prompt (sentence), a precomputed value to offer as default
  # (prefilled_value), and the diagnostic id forwarded across turns.
  # terminal? is true when the questionnaire is exhausted for this
  # indicator and the score can be computed.
  class Question
    attr_reader :next_indicator, :sentence, :prefilled_value, :diagnostic_id, :nature

    # Convenience factory for the "no more questions" case.
    def self.terminal(diagnostic_id: nil)
      new(diagnostic_id: diagnostic_id)
    end

    def initialize(next_indicator: nil, sentence: nil, prefilled_value: nil, diagnostic_id: nil, nature: nil)
      @next_indicator  = next_indicator
      @sentence        = sentence
      @prefilled_value = prefilled_value
      @diagnostic_id   = diagnostic_id
      @nature          = nature
    end

    def terminal?
      next_indicator.nil?
    end

    def as_json(_options = nil)
      {
        next_indicator: next_indicator,
        sentence: sentence,
        prefilled_value: prefilled_value,
        diagnostic_id: diagnostic_id,
        nature: nature,
        terminal: terminal?
      }
    end

    def to_h
      as_json
    end

    def ==(other)
      other.is_a?(Idea::Question) &&
        next_indicator  == other.next_indicator &&
        sentence        == other.sentence &&
        prefilled_value == other.prefilled_value &&
        diagnostic_id   == other.diagnostic_id &&
        nature          == other.nature
    end
    alias eql? ==

    def hash
      [next_indicator, sentence, prefilled_value, diagnostic_id, nature].hash
    end
  end
end
