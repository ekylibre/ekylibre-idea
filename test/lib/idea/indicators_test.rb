# frozen_string_literal: true

require 'test_helper'
require 'idea/indicators'

class IdeaIndicatorsTest < Minitest::Test
  def test_components_lists_all_five
    assert_equal %w[A1 A2 A3 A4 A5], Idea::Indicators.components
  end

  def test_scripted_components_excludes_a3_and_a5
    # A3 and A5's #next_question always returns terminal — no point
    # offering the wizard button for them in show.html.haml.
    assert_equal %w[A1 A2 A4], Idea::Indicators.scripted_components
  end

  def test_scripted_components_is_subset_of_components
    Idea::Indicators.scripted_components.each do |id|
      assert_includes Idea::Indicators.components, id
    end
  end

  def test_item_values_count_per_indicator
    assert_equal 12, Idea::Indicators.item_values_count('A1')
    assert_equal 28, Idea::Indicators.item_values_count('A2')
    assert_equal 14, Idea::Indicators.item_values_count('A3')
    assert_equal 26, Idea::Indicators.item_values_count('A4')
    assert_equal 6,  Idea::Indicators.item_values_count('A5')
  end

  def test_nature_for_known_floats
    # These power arithmetic in update_global_score (e.g. A4_16 / 100.0)
    # and must round-trip as floats, not strings.
    assert_equal 'float', Idea::Indicators.nature_for('A4_16')
    assert_equal 'float', Idea::Indicators.nature_for('A4_10')
    assert_equal 'float', Idea::Indicators.nature_for('A4_17')
    assert_equal 'float', Idea::Indicators.nature_for('A2_17')
  end

  def test_nature_for_known_integers
    assert_equal 'integer', Idea::Indicators.nature_for('A1_10')
    assert_equal 'integer', Idea::Indicators.nature_for('A2_5')
  end

  def test_nature_for_known_booleans
    assert_equal 'boolean', Idea::Indicators.nature_for('A4_9')
    assert_equal 'boolean', Idea::Indicators.nature_for('A2_1')
  end

  def test_nature_for_unknown_defaults_to_string
    assert_equal 'string', Idea::Indicators.nature_for('Z9_99')
    assert_equal 'string', Idea::Indicators.nature_for('')
  end

  def test_normalize_item_value_name_strips_zero_padding
    # Components emit 'A2_01' / 'A4_09' / 'A1_01'; rows in the DB are
    # named 'A2_1' / 'A4_9' / 'A1_1'. Normalize both to the unpadded form.
    assert_equal 'A2_1', Idea::Indicators.normalize_item_value_name('A2_01')
    assert_equal 'A4_9', Idea::Indicators.normalize_item_value_name('A4_09')
    assert_equal 'A1_1', Idea::Indicators.normalize_item_value_name('A1_01')
  end

  def test_normalize_item_value_name_leaves_two_digit_suffixes_alone
    assert_equal 'A1_10', Idea::Indicators.normalize_item_value_name('A1_10')
    assert_equal 'A2_17', Idea::Indicators.normalize_item_value_name('A2_17')
    assert_equal 'A4_21', Idea::Indicators.normalize_item_value_name('A4_21')
  end

  def test_nature_for_accepts_padded_names
    # Defensive: callers may forget to normalize. nature_for normalizes
    # internally so 'A2_01' resolves the same as 'A2_1'.
    assert_equal 'boolean', Idea::Indicators.nature_for('A2_01')
    assert_equal 'boolean', Idea::Indicators.nature_for('A4_09')
    assert_equal 'boolean', Idea::Indicators.nature_for('A1_01')
  end
end
