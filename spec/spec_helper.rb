require 'simplecov'
SimpleCov.start
require 'net/http'
require 'socket'
require 'yaml'
require 'json'
require 'fileutils'

require 'rspec'
require 'em-synchrony'
require 'em-synchrony/em-http'

FIXTURES_PATH= File.expand_path('../../spec/fixtures', __FILE__)
MOC_PARAMS = YAML.load(File.read(File.join(FIXTURES_PATH, 'params.yml')))

ENV['TESTING'] = 'true'
ENV['DATABASE_PATH'] = File.join(FIXTURES_PATH, 'memory.db')

require File.expand_path('../../lib/zygote.rb', __FILE__)

# Run within synchrony block to prevent blocking
module ZygoteSpec
  def self.append_features(mod)
    mod.class_eval %[
      around(:each) do |example|
        EM.synchrony do
          zygote(
            config_path: File.join(FIXTURES_PATH, 'cells.yml'),
            cells: File.join(FIXTURES_PATH, 'cells')
          ).start
          example.run
          EM.stop
        end
      end
    ]
  end
end

# Use a fresh database fro seed for each run
module MemorySpec
  def self.append_features(mod)
    mod.class_eval %[
      around(:each) do |example|
        seed = File.join(FIXTURES_PATH, 'memory_seed.db')
        FileUtils.cp(seed, ENV['DATABASE_PATH'])
        Memory::load
        example.run
      end
    ]
  end
end

def match_fixture(name, actual)
  path = File.expand_path("fixtures/data/#{name}.txt", File.dirname(__FILE__))
  File.open(path, 'w') { |f| f.write(actual) } if ENV['FIXTURE_RECORD']
  expect(actual).to eq(File.read(path))
end

# Returns EventMachine::HttpClient
def get(uri, params = {})
  uriq = "#{uri}#{parameterize(params)}"
  EM::Synchrony.sync(EventMachine::HttpRequest.new(File.join("http://#{Socket.gethostname}:7000/", uriq)).aget(query: params))
end

# Returns EventMachine::HttpClient
def delete(uri, params = {})
  uriq = "#{uri}#{parameterize(params)}"
  EM::Synchrony.sync(EventMachine::HttpRequest.new(File.join("http://#{Socket.gethostname}:7000/", uriq)).adelete(query: params))
end

# Returns EventMachine::HttpClient
def post(uri, params = {})
  EM::Synchrony.sync(EventMachine::HttpRequest.new("http://#{Socket.gethostname}:7000/#{uri}").apost(body: params))
end

def parameterize(params)
  q = URI.escape(params.collect { |k, v| "#{k}=#{v}" }.join('&'))
  q.empty? ? '' : "?#{q}"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
