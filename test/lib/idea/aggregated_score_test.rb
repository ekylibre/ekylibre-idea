# frozen_string_literal: true

require 'test_helper'
require 'idea/indicators'

# Lightweight doubles so we don't need to boot Rails to exercise
# Idea::Indicators.dimension_score and .global_score.
DiagnosticItemDouble = Struct.new(:idea_id, :name, :treshold, :group, :value)

class FakeDiagnostic
  attr_reader :idea_diagnostic_items

  def initialize(items)
    @idea_diagnostic_items = items
  end
end

class IdeaAggregatedScoreTest < Minitest::Test
  def fake_dim(dim, indicators)
    indicators.map do |id, value|
      ind = Idea::Indicators.find(id)
      DiagnosticItemDouble.new(id, ind[:label], ind[:treshold], dim, value)
    end
  end

  def test_dimension_score_returns_zero_when_no_items_answered
    diag = FakeDiagnostic.new(fake_dim('A', [['A1', nil], ['A2', nil]]))
    summary = Idea::Indicators.dimension_score(diag, 'A')

    assert_equal 0, summary[:score]
    assert_equal 0, summary[:answered]
    assert_equal 2, summary[:total]
    # Treshold sum is still meaningful even with no answers.
    assert summary[:max].positive?
    assert_equal 0, summary[:percent]
  end

  def test_dimension_score_aggregates_indicator_values
    # A1 has treshold 5; if we record value 5, that's 100% of A1.
    # Plus A2 value 2 on treshold 5 = 40% of A2.
    diag = FakeDiagnostic.new(fake_dim('A', [['A1', 5], ['A2', 2]]))
    summary = Idea::Indicators.dimension_score(diag, 'A')

    assert_equal 7, summary[:score]
    assert_equal 10, summary[:max]   # treshold 5 + 5
    assert_equal 2,  summary[:answered]
    assert_equal 2,  summary[:total]
    assert_in_delta 0.70, summary[:ratio], 1e-3
    assert_equal 70, summary[:percent]
  end

  def test_dimension_score_scoped_to_one_dimension
    items = fake_dim('A', [['A1', 5]]) + fake_dim('B', [['B1', 6]])
    diag = FakeDiagnostic.new(items)

    assert_equal 5, Idea::Indicators.dimension_score(diag, 'A')[:score]
    assert_equal 6, Idea::Indicators.dimension_score(diag, 'B')[:score]
    assert_equal 0, Idea::Indicators.dimension_score(diag, 'C')[:score]
  end

  def test_global_score_uses_weakest_dimension
    # A is at 100%, B at 50%, C at 0%. Global = min(A, B, C) → 0%.
    items =
      fake_dim('A', [['A1', 5]]) +
      fake_dim('B', [['B1', 3]]) +  # treshold 6 → 50%
      fake_dim('C', [['C1', 0]])    # treshold 20 → 0% (answered with 0)
    diag = FakeDiagnostic.new(items)

    global = Idea::Indicators.global_score(diag)
    assert_equal 0,    global[:percent]
    assert_equal 0.0,  global[:score_3]
    assert_equal 'C',  global[:weakest]
  end

  def test_global_score_with_partial_data
    # Only A has any score; B and C contribute 0 (max 0 → skipped).
    items = fake_dim('A', [['A1', 5]])
    diag = FakeDiagnostic.new(items)

    global = Idea::Indicators.global_score(diag)
    # Only A is "valid" (max > 0). Min over {A:100%} = 100%.
    assert_equal 100, global[:percent]
    assert_equal 3.0, global[:score_3]
    assert_equal 'A', global[:weakest]
  end

  def test_global_score_when_nothing_scored
    diag = FakeDiagnostic.new([])
    global = Idea::Indicators.global_score(diag)
    assert_equal 0, global[:percent]
    assert_equal 0.0, global[:score_3]
    assert_nil global[:weakest]
  end
end
