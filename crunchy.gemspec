# frozen_string_literal: true

require 'English'
require 'date'
require File.expand_path('lib/crunchy/version', __dir__)

Gem::Specification.new do |s|
  s.authors       = 'Martin Fenner'
  s.email         = 'martin@front-matter.io'
  s.name          = 'crunchy'
  s.homepage      = 'https://github.com/front-matter/crunchy'
  s.summary       = 'Ruby client for the Typesense search engine'
  s.description   = 'Ruby gem and client library for the Typesense search engine.'
  s.require_paths = ['lib']
  s.version       = Crunchy::VERSION.dup
  s.extra_rdoc_files = ['README.md']
  s.license = 'MIT'
  s.required_ruby_version = '>= 3.0.0'

  # Declare dependencies here, rather than in the Gemfile
  s.add_dependency 'activesupport', '~> 6.1', '>= 6.1.5'
  s.add_dependency 'typesense', '~> 0.15', '>= 0.15.0' 
  s.add_development_dependency 'bundler', '~> 2.3', '>= 2.3.1'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rubocop', '~> 1.36'
  s.add_development_dependency 'rubocop-rspec', '~> 2.13'
  s.add_development_dependency 'simplecov', '0.22.0'
  s.add_development_dependency 'simplecov_json_formatter', '~> 0.1.4'
  s.add_development_dependency 'vcr', '~> 6.0', '>= 6.1.0'
  s.add_development_dependency 'webmock', '~> 3.0', '>= 3.0.1'

  s.require_paths = ['lib']
  s.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.metadata['rubygems_mfa_required'] = 'true'
end
