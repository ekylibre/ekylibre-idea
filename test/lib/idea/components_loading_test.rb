# frozen_string_literal: true

require 'test_helper'
require 'yaml'

# These checks run without Rails — they only assert that every stub
# file under lib/idea/components/{a..c}<N>.rb declares the right class
# with the right constant. The actual behavior of Base#next_question /
# compute_score etc. needs Rails (models) and is exercised in Phase 5
# (controller + integration tests).

class IdeaComponentsLoadingTest < Minitest::Test
  COMPONENT_FILES = Dir[File.expand_path('../../../lib/idea/components/[abc][0-9]*.rb', __dir__)].freeze
  YAML_INDICATORS = YAML.safe_load(File.read(File.expand_path('../../../config/indicators.yml', __dir__)))['indicators'].map { |h| h['id'] }.freeze

  def test_yaml_lists_53_indicators
    assert_equal 53, YAML_INDICATORS.size
  end

  def test_each_indicator_has_a_component_file
    file_ids = COMPONENT_FILES.map { |p| File.basename(p, '.rb').upcase }.sort_by { |id| [id[0], id[1..].to_i] }
    yaml_ids = YAML_INDICATORS.sort_by { |id| [id[0], id[1..].to_i] }
    assert_equal yaml_ids, file_ids
  end

  def test_each_stub_declares_the_INDICATOR_constant
    # Parse the file source — avoid loading the class (which would need
    # Rails models for the A1-A5 implementations).
    COMPONENT_FILES.each do |path|
      content = File.read(path)
      id = File.basename(path, '.rb').upcase
      assert_match(/INDICATOR\s*=\s*['"]#{id}['"]/, content, "#{path} should declare INDICATOR = '#{id}'")
    end
  end

  def test_each_stub_inherits_from_base
    COMPONENT_FILES.each do |path|
      content = File.read(path)
      id = File.basename(path, '.rb').upcase
      assert_match(/class\s+#{id}\s*<\s*Base/, content, "#{path} should inherit from Base")
    end
  end

  def test_stub_files_under_dimension_groups
    a_count = COMPONENT_FILES.count { |p| File.basename(p, '.rb').start_with?('a') }
    b_count = COMPONENT_FILES.count { |p| File.basename(p, '.rb').start_with?('b') }
    c_count = COMPONENT_FILES.count { |p| File.basename(p, '.rb').start_with?('c') }
    assert_equal 19, a_count
    assert_equal 23, b_count
    assert_equal 11, c_count
  end
end
