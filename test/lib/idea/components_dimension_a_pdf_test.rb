# frozen_string_literal: true

# Re-use the value-injection harness defined in components_dimension_c_test.rb
require_relative 'components_dimension_c_test'

# Load the A6-A19 components against the stubbed Base.
%w[a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19].each do |c|
  require "idea/components/#{c}"
end

class DimensionA6A19ScoringTest < Minitest::Test
  # -- A6 — Autonomie en énergie/matériaux/semences --
  def test_a6_full_yields_max
    a6 = Idea::Components::A6.new.with_values(
      'A6_1' => true, 'A6_2' => true, 'A6_3' => true, 'A6_4' => true,
      'A6_5' => true, 'A6_8' => true, 'A6_10' => true
    )
    # item1=3, item2=3, item3=3 → 9 capped at 8
    assert_equal 8, a6.compute_score
  end

  def test_a6_partial
    a6 = Idea::Components::A6.new.with_values('A6_1' => true)
    assert_equal 3, a6.compute_score
  end

  # -- A7 — élevage conditionnel --
  def test_a7_no_livestock_yields_zero
    a7 = Idea::Components::A7.new.with_values(
      'A7_1' => 0, 'A7_2' => 0, 'A7_3' => 0, 'A7_4' => 0, 'A7_5' => 0
    )
    assert_equal 0, a7.compute_score
  end

  def test_a7_full_autonomy_yields_max_herbivore
    # purchased = 0, consumed = 100 → ratio 1.0 → score 8
    a7 = Idea::Components::A7.new.with_values(
      'A7_1' => 0, 'A7_2' => 100, 'A7_3' => 0, 'A7_4' => 100, 'A7_5' => 2
    )
    assert_equal 8, a7.compute_score
  end

  def test_a7_monogastric_uses_concentrates_only
    a7 = Idea::Components::A7.new.with_values(
      'A7_1' => 50, 'A7_2' => 50, 'A7_3' => 0, 'A7_4' => 100, 'A7_5' => 1
    )
    # only item 2: ratio 1.0 → 8
    assert_equal 8, a7.compute_score
  end

  # -- A8 — AUT_N thresholds --
  def test_a8_low_imported_high_score
    # imported small, total spread non-zero, fixed non-zero → high AUT_N
    a8 = Idea::Components::A8.new.with_values(
      'A8_1' => 10, 'A8_5' => 10, 'A8_7' => 100, 'A8_8' => 50, 'A8_9' => 0.5, 'A8_11' => 200
    )
    # imported = 20, denom = 150 + 100 = 250 → AUT_N = 1 - 20/250 = 0.92 → 8
    assert_equal 8, a8.compute_score
  end

  def test_a8_high_imported_low_score
    a8 = Idea::Components::A8.new.with_values(
      'A8_1' => 200, 'A8_5' => 0, 'A8_7' => 100, 'A8_8' => 0, 'A8_9' => 0, 'A8_11' => 0
    )
    # imported = 200, denom = 100 → AUT_N = 1 - 2 = -1 (clamped to bucket 0)
    assert_equal 0, a8.compute_score
  end

  # -- A10 — phosphore --
  def test_a10_low_p_yields_max
    # A10_1 = 0.1 tonnes × A10_2 = 30 kg/t = 3 kg / SAU 100 ha = 0.03 kg/ha → 8
    a10 = Idea::Components::A10.new.with_values('A10_1' => 0.1, 'A10_2' => 30, 'A10_3' => 100)
    assert_equal 8, a10.compute_score
  end

  def test_a10_high_p_yields_zero
    # A10_1 = 100 tonnes × A10_2 = 500 kg/t = 50_000 kg / 100 ha = 500 kg/ha → 0
    a10 = Idea::Components::A10.new.with_values('A10_1' => 100, 'A10_2' => 500, 'A10_3' => 100)
    assert_equal 0, a10.compute_score
  end

  # -- A11 — CEDI --
  def test_a11_low_consumption_max
    a11 = Idea::Components::A11.new.with_values(
      'A11_1' => 100, 'A11_2' => 0, 'A11_3' => 0, 'A11_4' => 0, 'A11_5' => 0,
      'A11_6' => 0, 'A11_7' => 0, 'A11_8' => 0, 'A11_9' => 0, 'A11_10' => 0,
      'A11_11' => 0, 'A11_12' => 0, 'A11_13' => 0, 'A11_14' => 0, 'A11_15' => 0,
      'A11_16' => 0, 'A11_17' => 0, 'A11_18' => 1, 'A11_19' => 100
    )
    # CEDI = 100 / 100 = 1 → < 500 → 8
    assert_equal 8, a11.compute_score
  end

  # -- A12 — water management --
  def test_a12_full_water_practices
    values = (1..13).each_with_object({}) { |i, h| h["A12_#{i}"] = true }
    a12 = Idea::Components::A12.new.with_values(values)
    # item1=4 (A12_4,5,9,13), item2=5 (A12_6,7,8,10,11), item3=1 → 10 capped at 8
    assert_equal 8, a12.compute_score
  end

  # -- A13 — fertility --
  def test_a13_partial_fertility
    a13 = Idea::Components::A13.new.with_values(
      'A13_1' => 2, 'A13_4' => true, 'A13_5' => false, 'A13_6' => true, 'A13_9' => true
    )
    # item1=2, item2=2 (A13_4 + A13_6), item3=2 → 6
    assert_equal 6, a13.compute_score
  end

  # -- A14 — sanitary protection (conditional) --
  def test_a14_no_inputs_yields_max
    a14 = Idea::Components::A14.new.with_values('A14_1' => false, 'A14_2' => false)
    assert_equal 4, a14.compute_score
  end

  def test_a14_plant_only_full_rotation
    a14 = Idea::Components::A14.new.with_values(
      'A14_1' => true, 'A14_2' => false, 'A14_3' => 2
    )
    assert_equal 4, a14.compute_score
  end

  def test_a14_plant_and_animal_minimum
    a14 = Idea::Components::A14.new.with_values(
      'A14_1' => true, 'A14_2' => true, 'A14_3' => 2,    # item1 = 4
      'A14_4' => true, 'A14_5' => false                  # item2 = 2
    )
    assert_equal 2, a14.compute_score  # min(4, 2)
  end

  def test_a14_critical_antibiotic_malus
    a14 = Idea::Components::A14.new.with_values(
      'A14_1' => true, 'A14_2' => true, 'A14_3' => 2,
      'A14_4' => true, 'A14_5' => true, 'A14_6' => true
    )
    # min(item1=4, item2=4) = 4, malus -1 = 3
    assert_equal 3, a14.compute_score
  end

  # -- A15 — production resources --
  def test_a15_no_problems
    a15 = Idea::Components::A15.new.with_values(
      'A15_1' => false, 'A15_5' => false, 'A15_3' => 0, 'A15_4' => 0
    )
    # item1=2 (no supply pb), item2=1 (no livestock), item3=1 (no labor pb) → 4
    assert_equal 4, a15.compute_score
  end

  # -- A16 — water quality --
  def test_a16_low_pressure_high_score
    a16 = Idea::Components::A16.new.with_values(
      'A16_2' => 100, 'A16_3' => 50, 'A16_5' => 0, 'A16_45' => 0.5,
      'A16_46' => true, 'A16_47' => true, 'A16_48' => false
    )
    # item1: pressure = 50/100 = 0.5 < 100 → 2
    # item2: IFT 0.5 < 1 → 3
    # item3: 2 actions → 2
    # → 7 capped at 6
    assert_equal 6, a16.compute_score
  end

  # -- A17 — air quality --
  def test_a17_low_emissions_yields_max
    a17 = Idea::Components::A17.new.with_values(
      'A17_1' => 1.5, 'A17_4' => true, 'A17_5' => true,
      'A17_6' => true, 'A17_7' => true, 'A17_8' => true, 'A17_11' => false
    )
    # item1 = 2 (EPE < 2), item2 = 3 (3 truths capped at 2), item3 = 2, no malus
    # actually item2 is capped at 2, total = 2 + 2 + 2 = 6
    assert_equal 6, a17.compute_score
  end

  # -- A19 — phyto/veto reduction --
  def test_a19_no_inputs_low_ift_yields_high_plant_score
    a19 = Idea::Components::A19.new.with_values(
      'A19_1' => 0.5, 'A19_2' => false, 'A19_3' => false, 'A19_4' => false,
      'A19_5' => false, 'A19_6' => false
    )
    # ift_score = 4 (ift < 1), alternatives = 0 → 4
    assert_equal 4, a19.compute_score
  end
end
