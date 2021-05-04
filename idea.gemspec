# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'idea/version'

Gem::Specification.new do |spec|
  spec.name          = 'idea'
  spec.version       = IDEA::VERSION
  spec.authors       = ['MSJarre']
  spec.email         = ['mlabous@ekylibre.com']

  spec.summary       = 'IDEA plugin Ekylibre'
  spec.homepage      = 'https://ekylibre.com'

  spec.add_development_dependency 'bundler', '~> 2.2.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '1.11.0'
end
