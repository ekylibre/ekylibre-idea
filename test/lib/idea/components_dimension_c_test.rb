# frozen_string_literal: true

require 'test_helper'
require 'idea/question'
require 'idea/sentence_helpers'
require 'idea/indicators'

# Stub the Rails-side classes so we can load and unit-test the Dimension C
# scoring formulas without booting the main repo. We swap item() and the
# Idea::Components::Base ancestors via lightweight doubles.
module IdeaDoubles
  ItemValue = Struct.new(:name, :value)
end

require 'idea/components/base'

# Replace `item` lookup on Base so tests can inject pre-baked values.
module Idea
  module Components
    class Base
      def item(idea_id)
        @injected_values&.[](idea_id) || @injected_values&.[](Idea::Indicators.normalize_item_value_name(idea_id))
      end

      def with_values(values)
        @injected_values = values.transform_values { |v| IdeaDoubles::ItemValue.new(nil, v) }
        self
      end
    end
  end
end

# Skip the real initialize — it expects an IdeaDiagnostic ActiveRecord.
module Idea
  module Components
    class Base
      def initialize(diagnostic_id: nil, idea_name: nil)
        @indicator_id = idea_name
      end
    end
  end
end

require 'idea/components/c1'
require 'idea/components/c2'
require 'idea/components/c3'
require 'idea/components/c4'
require 'idea/components/c5'
require 'idea/components/c6'
require 'idea/components/c7'
require 'idea/components/c9'
require 'idea/components/c10'
require 'idea/components/c11'

class DimensionCScoringTest < Minitest::Test
  # -- C1 — Capacité économique --

  def test_c1_zero_ratio_yields_zero
    c1 = Idea::Components::C1.new.with_values(
      'C1_1' => 0, 'C1_2' => 0, 'C1_3' => 0, 'C1_4' => 18000, 'C1_5' => 1, 'C1_6' => 0
    )
    assert_equal 0, c1.compute_score
  end

  def test_c1_mid_ratio_yields_partial
    # CE = (40000 - 0 - 0) / 1 = 40000 ; SMIC 18000 → ratio ≈ 2.22 → item1=16, item2=2 → 18
    c1 = Idea::Components::C1.new.with_values(
      'C1_1' => 40000, 'C1_2' => 0, 'C1_3' => 0, 'C1_4' => 18000, 'C1_5' => 1, 'C1_6' => 2
    )
    assert_equal 18, c1.compute_score
  end

  def test_c1_high_ratio_capped_at_20
    c1 = Idea::Components::C1.new.with_values(
      'C1_1' => 100000, 'C1_2' => 0, 'C1_3' => 0, 'C1_4' => 18000, 'C1_5' => 1, 'C1_6' => 5
    )
    assert_equal 20, c1.compute_score
  end

  def test_c1_nil_when_not_computable
    c1 = Idea::Components::C1.new.with_values('C1_1' => 40000)
    refute c1.computable?
    assert_nil c1.compute_score
  end

  # -- C2 — Capacité de remboursement --

  def test_c2_low_debt_yields_max
    # PdD = (2000 + 100) / 50000 = 4.2% → score 12
    c2 = Idea::Components::C2.new.with_values('C2_1' => 2000, 'C2_2' => 100, 'C2_3' => 50000)
    assert_equal 12, c2.compute_score
  end

  def test_c2_high_debt_yields_zero
    # PdD = (40000 + 5000) / 50000 = 90% → 0
    c2 = Idea::Components::C2.new.with_values('C2_1' => 40000, 'C2_2' => 5000, 'C2_3' => 50000)
    assert_equal 0, c2.compute_score
  end

  # -- C3 — Endettement structurel --

  def test_c3_low_debt_ratio_yields_max
    # TES = 10000 / (10000 + 50000 + 10000) = 14% → 6
    c3 = Idea::Components::C3.new.with_values('C3_1' => 10000, 'C3_2' => 50000, 'C3_3' => 10000)
    assert_equal 6, c3.compute_score
  end

  def test_c3_high_debt_ratio_yields_zero
    # TES = 80000 / 100000 = 80% → 0
    c3 = Idea::Components::C3.new.with_values('C3_1' => 80000, 'C3_2' => 15000, 'C3_3' => 5000)
    assert_equal 0, c3.compute_score
  end

  # -- C4 — Diversification productive --

  def test_c4_best_case_caps_at_10
    # rank 1 (atelier <50%) → 8 ; rank 1 (>3 produits) → 4 ; sum = 12 capped to 10
    c4 = Idea::Components::C4.new.with_values('C4_1' => 1, 'C4_2' => 1)
    assert_equal 10, c4.compute_score
  end

  def test_c4_no_diversification_yields_zero
    # rank 4 (atelier >95%) → 0 ; rank 3 (1 produit) → 0
    c4 = Idea::Components::C4.new.with_values('C4_1' => 4, 'C4_2' => 3)
    assert_equal 0, c4.compute_score
  end

  # -- C5 --

  def test_c5_with_malus
    # rank 1 (client <33%) → 6 ; rank 4 (AMAP) → 6 ; malus -2 → 10
    c5 = Idea::Components::C5.new.with_values('C5_1' => 1, 'C5_2' => 4, 'C5_3' => true)
    assert_equal 10, c5.compute_score
  end

  def test_c5_no_contract_no_malus
    c5 = Idea::Components::C5.new.with_values('C5_1' => 3, 'C5_2' => 1, 'C5_3' => false)
    assert_equal 0, c5.compute_score
  end

  # -- C6 --

  def test_c6_low_aid_dependency_yields_max
    c6 = Idea::Components::C6.new.with_values('C6_1' => 5000, 'C6_2' => 50000)
    assert_equal 6, c6.compute_score
  end

  def test_c6_aid_exceeds_ebe_yields_zero
    c6 = Idea::Components::C6.new.with_values('C6_1' => 60000, 'C6_2' => 50000)
    assert_equal 0, c6.compute_score
  end

  # -- C7 --

  def test_c7_with_external_income
    c7 = Idea::Components::C7.new.with_values('C7_1' => true)
    assert_equal 4, c7.compute_score
  end

  def test_c7_without_external_income
    c7 = Idea::Components::C7.new.with_values('C7_1' => false)
    assert_equal 0, c7.compute_score
  end

  # -- C9 --

  def test_c9_all_positive_signals_caps_at_8
    c9 = Idea::Components::C9.new.with_values('C9_1' => 1, 'C9_2' => true, 'C9_3' => true, 'C9_4' => 1)
    # 4 + 2 + 1 + 2 = 9 capped to 8
    assert_equal 8, c9.compute_score
  end

  def test_c9_worst_case_yields_zero
    c9 = Idea::Components::C9.new.with_values('C9_1' => 4, 'C9_2' => false, 'C9_3' => false, 'C9_4' => 3)
    assert_equal 0, c9.compute_score
  end

  # -- C10 --

  def test_c10_efficient_process
    # production = 100k+0+0-0 = 100k ; eb = (100k-30k)/100k = 0.7 → 12
    c10 = Idea::Components::C10.new.with_values(
      'C10_1' => 100000, 'C10_2' => 0, 'C10_3' => 0, 'C10_4' => 0, 'C10_5' => 30000
    )
    assert_equal 12, c10.compute_score
  end

  def test_c10_loss_making
    # eb < 0.1 → 0
    c10 = Idea::Components::C10.new.with_values(
      'C10_1' => 100000, 'C10_2' => 0, 'C10_3' => 0, 'C10_4' => 0, 'C10_5' => 95000
    )
    assert_equal 0, c10.compute_score
  end

  # -- C11 --

  def test_c11_low_inputs_yields_max
    # SI = 30000/100 = 300 €/ha → 8
    c11 = Idea::Components::C11.new.with_values('C11_1' => 100, 'C11_2' => 30000)
    assert_equal 8, c11.compute_score
  end

  def test_c11_high_inputs_yields_zero
    # SI = 200000/100 = 2000 €/ha → 0
    c11 = Idea::Components::C11.new.with_values('C11_1' => 100, 'C11_2' => 200000)
    assert_equal 0, c11.compute_score
  end
end
