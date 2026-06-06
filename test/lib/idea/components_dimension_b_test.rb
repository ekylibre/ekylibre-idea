# frozen_string_literal: true

# Reuses the value-injection harness defined in
# components_dimension_c_test.rb (Base#item / Base#with_values are
# redefined there to short-circuit ActiveRecord). Loading the C test
# file first gives us that harness for free here.

require_relative 'components_dimension_c_test'

# Now load the B components against the stubbed Base.
require 'idea/components/b1'
require 'idea/components/b2'
require 'idea/components/b3'
require 'idea/components/b4'
require 'idea/components/b5'
require 'idea/components/b6'
require 'idea/components/b7'
require 'idea/components/b10'
require 'idea/components/b13'
require 'idea/components/b15'
require 'idea/components/b18'
require 'idea/components/b20'
require 'idea/components/b21'
require 'idea/components/b22'

class DimensionBScoringTest < Minitest::Test
  # B1 — quality presence
  def test_b1_both_items_yields_max
    b1 = Idea::Components::B1.new.with_values('B1_3' => true, 'B1_4' => true)
    assert_equal 6, b1.compute_score
  end

  def test_b1_neither_item_yields_zero
    b1 = Idea::Components::B1.new.with_values('B1_3' => false, 'B1_4' => false)
    assert_equal 0, b1.compute_score
  end

  # B4 — 9 actions, 2 points each, capped at 6
  def test_b4_all_actions_caps_at_6
    values = (1..9).each_with_object({}) { |i, h| h["B4_#{i}"] = true }
    b4 = Idea::Components::B4.new.with_values(values)
    assert_equal 6, b4.compute_score
  end

  def test_b4_single_action_yields_2
    b4 = Idea::Components::B4.new.with_values('B4_1' => true, 'B4_2' => false)
    assert_equal 2, b4.compute_score
  end

  # B5 — 3 items × 3 points
  def test_b5_full_max
    b5 = Idea::Components::B5.new.with_values('B5_1' => true, 'B5_2' => true, 'B5_3' => true)
    assert_equal 6, b5.compute_score  # 9 capped at 6
  end

  def test_b5_two_items
    b5 = Idea::Components::B5.new.with_values('B5_1' => true, 'B5_2' => true, 'B5_3' => false)
    assert_equal 6, b5.compute_score
  end

  # B7 — 3 items × 2 points capped at 3
  def test_b7_full_capped
    b7 = Idea::Components::B7.new.with_values('B7_1' => true, 'B7_2' => true, 'B7_3' => true)
    assert_equal 3, b7.compute_score
  end

  def test_b7_single_item_yields_2
    b7 = Idea::Components::B7.new.with_values('B7_1' => true)
    assert_equal 2, b7.compute_score
  end

  # B10 — 8 items × 1 point capped at 3
  def test_b10_three_items_caps_at_3
    b10 = Idea::Components::B10.new.with_values('B10_1' => true, 'B10_2' => true, 'B10_3' => true)
    assert_equal 3, b10.compute_score
  end

  # B13 — 2 items × 2
  def test_b13_one_item
    b13 = Idea::Components::B13.new.with_values('B13_1' => true)
    assert_equal 2, b13.compute_score
  end

  # B15 — 5 items × 2 capped at 6
  def test_b15_full_capped
    b15 = Idea::Components::B15.new.with_values(
      'B15_1' => true, 'B15_2' => true, 'B15_3' => true, 'B15_4' => true, 'B15_5' => true
    )
    assert_equal 6, b15.compute_score  # 10 capped at 6
  end

  # B18 — 3 items × 2
  def test_b18_two_items
    b18 = Idea::Components::B18.new.with_values('B18_1' => true, 'B18_2' => true)
    assert_equal 4, b18.compute_score
  end

  # B20 — 3 items × 2 capped at 6
  def test_b20_max
    b20 = Idea::Components::B20.new.with_values('B20_1' => true, 'B20_2' => true, 'B20_3' => true)
    assert_equal 6, b20.compute_score
  end

  # B21 — self-assessment (rank)
  def test_b21_passes_value_through
    b21 = Idea::Components::B21.new.with_values('B21_1' => 4)
    assert_equal 4, b21.compute_score
  end

  def test_b21_capped_at_max
    b21 = Idea::Components::B21.new.with_values('B21_1' => 10)
    assert_equal 6, b21.compute_score
  end

  def test_b21_clamped_at_zero
    b21 = Idea::Components::B21.new.with_values('B21_1' => -2)
    assert_equal 0, b21.compute_score
  end

  # B22
  def test_b22_one_item
    b22 = Idea::Components::B22.new.with_values('B22_1' => true)
    assert_equal 3, b22.compute_score
  end

  def test_b22_both_items_capped
    b22 = Idea::Components::B22.new.with_values('B22_1' => true, 'B22_2' => true)
    assert_equal 6, b22.compute_score
  end

  # Computable? — all of B17 (13 items) only needs one to be present
  def test_b17_computable_with_partial_data
    require 'idea/components/b17'
    b17 = Idea::Components::B17.new.with_values('B17_1' => true)
    assert b17.computable?
  end

  def test_b21_not_computable_when_value_absent
    b21 = Idea::Components::B21.new.with_values({})
    refute b21.computable?
    assert_nil b21.compute_score
  end
end
