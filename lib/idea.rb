# frozen_string_literal: true

require 'idea/engine'
require 'idea/version'
require 'idea/ext_navigation'

# Analytics on farm performance towards durability
module Idea
  # parse transcodings
  # @return [OpenStruc] with keys: permanent_grasslands, low_number_animals, ecological_interest_areas
  def self.transcodings
    transcoding_path = File.join(File.dirname(__dir__), 'config', 'transcodings.json')
    JSON.parse(File.read(transcoding_path), object_class: OpenStruct)
  end

  # @returns [Array] all grasslands pac codes
  def self.permanent_grassland_codes
    transcodings.permanent_grassland.map(&:code)
  end

  def self.root
    Pathname.new(File.dirname(__dir__))
  end

end
