# frozen_string_literal: true

require 'test_helper'
require 'idea/indicators'

class IdeaIndicatorsTest < Minitest::Test
  def teardown
    Idea::Indicators.reload!
  end

  def test_registry_loads_53_indicators_from_yaml
    assert_equal 53, Idea::Indicators.all.size
  end

  def test_dimensions_breakdown_matches_idea4_spec
    assert_equal 19, Idea::Indicators.by_dimension('A').size
    assert_equal 23, Idea::Indicators.by_dimension('B').size
    assert_equal 11, Idea::Indicators.by_dimension('C').size
  end

  def test_components_lists_all_53_in_order
    ids = Idea::Indicators.components
    assert_equal 53, ids.size
    assert_equal 'A1', ids.first
    assert_equal 'C11', ids.last
  end

  def test_find_returns_indicator_hash
    ind = Idea::Indicators.find('A6')
    assert ind
    assert_equal 'A6', ind[:id]
    assert_equal 'A', ind[:dimension]
    refute_empty ind[:items]
  end

  def test_label_for_returns_human_label
    assert_includes Idea::Indicators.label_for('A4'), 'organisation spatiale'
  end

  def test_treshold_for_returns_idea4_real_values
    # A6 == 8 per the Dimension A PDF (item1+item2+item3 capped at 8).
    # A1 still uses the legacy 5 from Idea::Indicators.functional_diversity_attributes.
    assert_equal 8, Idea::Indicators.treshold_for('A6')
    assert_equal 4, Idea::Indicators.treshold_for('C7')
    assert_equal 6, Idea::Indicators.treshold_for('B21')
  end

  def test_scripted_components_includes_indicators_with_wizard_items
    assert_includes Idea::Indicators.scripted_components, 'A1'
    assert_includes Idea::Indicators.scripted_components, 'A2'
    assert_includes Idea::Indicators.scripted_components, 'A4'
  end

  def test_has_questions_is_true_for_scripted_indicators
    assert Idea::Indicators.has_questions?('A1')
    assert Idea::Indicators.has_questions?('A4')
  end

  def test_item_values_count_matches_yaml
    assert_equal 12, Idea::Indicators.item_values_count('A1')
    assert_equal 28, Idea::Indicators.item_values_count('A2')
    assert_equal 26, Idea::Indicators.item_values_count('A4')
    assert_equal 34, Idea::Indicators.item_values_count('B23')
    assert_equal 6,  Idea::Indicators.item_values_count('C1')
  end

  def test_items_for_returns_array_of_item_descriptors
    items = Idea::Indicators.items_for('A4')
    assert_equal 26, items.size
    assert items.first.key?(:id)
    assert items.first.key?(:nature)
    assert items.first.key?(:source)
  end

  def test_nature_for_known_floats
    assert_equal 'float', Idea::Indicators.nature_for('A4_16')
    assert_equal 'float', Idea::Indicators.nature_for('A4_10')
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

  def test_all_item_attributes_emits_one_hash_per_indicator
    attrs = Idea::Indicators.all_item_attributes
    assert_equal 53, attrs.size
    sample = attrs.first
    assert sample.key?(:idea_id)
    assert sample.key?(:name)
    assert sample.key?(:treshold)
    assert sample.key?(:group)
    assert_equal 'A1', sample[:idea_id]
    assert_equal 'A', sample[:group]
  end

  def test_dimensions_constant_exposes_three_dimensions
    assert_equal %w[A B C], Idea::Indicators::DIMENSIONS.keys.sort
  end
end
