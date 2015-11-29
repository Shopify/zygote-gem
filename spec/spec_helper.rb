require 'simplecov'
SimpleCov.start
require 'yaml'
require 'json'

FIXTURES_PATH = File.expand_path('../../spec/fixtures', __FILE__)
MOC_PARAMS = YAML.load(File.read(File.join(FIXTURES_PATH, 'params.yml')))

ENV['TESTING'] = 'true'
ENV['DATABASE_PATH'] = File.join(FIXTURES_PATH, 'memory.db')

require File.expand_path('../../lib/zygote.rb', __FILE__)
require 'zygote/test'
include Zygote

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
