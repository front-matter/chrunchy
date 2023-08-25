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
  s.test_files    = s.files.grep(%r{^(spec)/})
  
  # Declare dependencies here, rather than in the Gemfile
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'elasticsearch-extensions'
  s.add_development_dependency 'mock_redis'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.7.0'
  s.add_development_dependency 'rspec-collection_matchers'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'rubocop', '1.11'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'timecop'

  s.add_development_dependency 'method_source'
  s.add_development_dependency 'unparser'

  s.add_dependency 'activesupport', '>= 5.2'
  s.add_dependency 'elasticsearch', '>= 7.12.0', '< 7.14.0'
  s.add_dependency 'elasticsearch-dsl'

  s.require_paths = ['lib']
  s.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.metadata['rubygems_mfa_required'] = 'true'
end
