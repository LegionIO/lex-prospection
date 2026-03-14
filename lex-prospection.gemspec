# frozen_string_literal: true

require_relative 'lib/legion/extensions/prospection/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-prospection'
  spec.version       = Legion::Extensions::Prospection::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@iverson.io']

  spec.summary       = 'Affective forecasting and mental time travel for LegionIO'
  spec.description   = 'Future-oriented mental simulation: imagines future scenarios, predicts their emotional ' \
                       'impact, tracks impact bias and focalism corrections, and calibrates forecast accuracy ' \
                       'over time. Based on Gilbert & Wilson affective forecasting research.'
  spec.homepage      = 'https://github.com/LegionIO/lex-prospection'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
