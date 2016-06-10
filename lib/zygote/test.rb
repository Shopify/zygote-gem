require 'net/http'
require 'socket'
require 'fileutils'

require 'rspec'
require 'em-synchrony'
require 'em-synchrony/em-http'

module Zygote
  module TestConfig
    extend self
    attr_reader :config_path, :cells, :port, :fixtures
    def setup(fixtures: nil, config_path: nil, cells: nil, port: nil)
      @fixtures = fixtures || File.expand_path('../../../spec/fixtures', __FILE__)
      @config_path = config_path || File.join(@fixtures, 'cells.yml')
      @cells = cells || File.join(@fixtures, 'cells')
      @port = port || 7000
    end
  end

  # Run within synchrony block to prevent blocking
  module ZygoteSpec
    def self.append_features(mod)
      mod.class_eval %[
        around(:each) do |example|
          EM.synchrony do
            ZygoteServer.new(
              config_path: TestConfig.config_path,
              cells: TestConfig.cells
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
          seed = File.join(TestConfig.fixtures, 'memory_seed.db')
          FileUtils.cp(seed, ENV['DATABASE_PATH'])
          Memory::load
          example.run
        end
      ]
    end
  end

  def match_fixture(name, actual)
    path = File.join(TestConfig.fixtures, 'data', "#{name}.txt")
    File.open(path, 'w') { |f| f.write(actual) } if ENV['FIXTURE_RECORD']
    expect(actual).to eq(File.read(path))
  end

  # Returns EventMachine::HttpClient
  def get(uri, params = {})
    uriq = "#{uri}#{parameterize(params)}"
    EM::Synchrony.sync(EventMachine::HttpRequest.new(File.join("http://127.0.0.1:#{TestConfig.port}/", uriq)).aget(query: params))
  end

  # Returns EventMachine::HttpClient
  def delete(uri, params = {})
    uriq = "#{uri}#{parameterize(params)}"
    EM::Synchrony.sync(EventMachine::HttpRequest.new(File.join("http://127.0.0.1:#{TestConfig.port}/", uriq)).adelete(query: params))
  end

  # Returns EventMachine::HttpClient
  def post(uri, params = {})
    EM::Synchrony.sync(EventMachine::HttpRequest.new("http://127.0.0.1:#{TestConfig.port}/#{uri}").apost(body: JSON.dump(params), head: {'Content-Type' => 'application/json'}))
  end

  def parameterize(params)
    q = params.to_query
    q.empty? ? '' : "?#{q}"
  end
end
