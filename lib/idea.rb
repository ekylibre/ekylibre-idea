# frozen_string_literal: true

require 'idea/engine'
require 'idea/version'
require 'idea/ext_navigation'
require 'idea/indicators'
require 'idea/question'
require 'idea/sentence_helpers'
require 'idea/components/base'

# Load every component matching lib/idea/components/[abc]<digits>.rb so
# the 53-indicator catalog stays in sync with config/indicators.yml
# without us hand-maintaining a require list.
Dir[File.join(__dir__, 'idea', 'components', '[abc][0-9]*.rb')]
  .sort_by { |p| [File.basename(p, '.rb')[0], File.basename(p, '.rb')[1..].to_i] }
  .each { |p| require p }

# Analytics on farm performance towards durability
module Idea
  # parse transcodings
  # @return [OpenStruc] with keys: permanent_grasslands, low_number_animals, ecological_interest_areas
  def self.transcodings
    transcoding_path = File.join(File.dirname(__dir__), 'config', 'transcodings.json')
    JSON.parse(File.read(transcoding_path), object_class: OpenStruct)
  end

  def self.component_treshold(component)
    {
      functional_diversity: 20
    }[component]
  end

  # @returns [Array] all grasslands pac codes
  def self.permanent_grassland_codes
    transcodings.permanent_grassland.map(&:code)
  end

  def self.root
    Pathname.new(File.dirname(__dir__))
  end

end
