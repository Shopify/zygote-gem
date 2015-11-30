require 'simplecov'
SimpleCov.start
require 'yaml'
require 'json'

require 'zygote/test'
include Zygote
TestConfig.setup

ENV['TESTING'] = 'true'
ENV['DATABASE_PATH'] = File.join(TestConfig.fixtures, 'memory.db')
MOC_PARAMS = YAML.load(File.read(File.join(TestConfig.fixtures, 'params.yml')))

require File.expand_path('../../lib/zygote.rb', __FILE__)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
