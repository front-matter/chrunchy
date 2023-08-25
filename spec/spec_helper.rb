# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

require 'simplecov'
require 'simplecov_json_formatter'
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

require 'crunchy'
require 'rspec'
require 'webmock/rspec'
require 'vcr'

RSpec.configure do |config|
  config.order = :random
  config.include WebMock::API
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    ARGV.replace []
  end
end

def fixture_path
  "#{File.expand_path('fixtures', __dir__)}/"
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.default_cassette_options = { record: :new_episodes }
  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
end
