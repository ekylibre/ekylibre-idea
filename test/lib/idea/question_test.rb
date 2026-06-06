# frozen_string_literal: true

require 'test_helper'
require 'idea/question'

class IdeaQuestionTest < Minitest::Test
  def test_defaults_to_terminal_with_all_fields_nil
    q = Idea::Question.new

    assert_nil q.next_indicator
    assert_nil q.sentence
    assert_nil q.prefilled_value
    assert_nil q.diagnostic_id
    assert q.terminal?
  end

  def test_terminal_factory_carries_diagnostic_id
    q = Idea::Question.terminal(diagnostic_id: 42)

    assert q.terminal?
    assert_equal 42, q.diagnostic_id
  end

  def test_non_terminal_when_next_indicator_present
    q = Idea::Question.new(next_indicator: 'A1_10', diagnostic_id: 7)

    refute q.terminal?
    assert_equal 'A1_10', q.next_indicator
  end

  def test_carries_full_payload
    q = Idea::Question.new(
      next_indicator: 'A4_10',
      sentence: '<div>Fallow area</div>',
      prefilled_value: 12.5,
      diagnostic_id: 7
    )

    assert_equal 'A4_10', q.next_indicator
    assert_equal '<div>Fallow area</div>', q.sentence
    assert_in_delta 12.5, q.prefilled_value, 1e-6
    assert_equal 7, q.diagnostic_id
  end

  def test_as_json_returns_all_fields_with_terminal_flag
    q = Idea::Question.new(
      next_indicator: 'A1_10',
      sentence: 'Confirme la surface',
      prefilled_value: 18,
      diagnostic_id: 3,
      nature: 'integer'
    )

    assert_equal(
      {
        next_indicator: 'A1_10',
        sentence: 'Confirme la surface',
        prefilled_value: 18,
        diagnostic_id: 3,
        nature: 'integer',
        terminal: false
      },
      q.as_json
    )
  end

  def test_as_json_terminal_carries_true_flag
    assert_equal true, Idea::Question.terminal.as_json[:terminal]
  end

  def test_to_h_is_alias_of_as_json
    q = Idea::Question.new(next_indicator: 'A2_06', diagnostic_id: 1)
    assert_equal q.as_json, q.to_h
  end

  def test_equality_by_value
    a = Idea::Question.new(next_indicator: 'A1_10', diagnostic_id: 1)
    b = Idea::Question.new(next_indicator: 'A1_10', diagnostic_id: 1)
    c = Idea::Question.new(next_indicator: 'A1_10', diagnostic_id: 2)

    assert_equal a, b
    refute_equal a, c
    assert_equal a.hash, b.hash
  end

  def test_equality_rejects_other_types
    refute_equal Idea::Question.terminal, Object.new
  end
end
