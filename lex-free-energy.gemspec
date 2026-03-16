# frozen_string_literal: true

require_relative 'lib/legion/extensions/free_energy/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-free-energy'
  spec.version       = Legion::Extensions::FreeEnergy::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LegionIO free energy principle extension'
  spec.description   = 'Free energy minimization for LegionIO — Friston active inference, ' \
                       'precision-weighted prediction errors, and surprise-driven belief revision'
  spec.homepage      = 'https://github.com/LegionIO/lex-free-energy'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['documentation_uri']     = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
