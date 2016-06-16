require 'zygote/http'
require 'thin'

# Main zygote namespace
module Zygote
  # Wrapper around thin / event machine to run zygote sinatra rack app in.
  class Server
    def initialize(port: 7000, threads: 1000, host: '0.0.0.0', config_path: nil, cells: [], debug: false)
      debug ||= ENV['DEBUG']

      cell_config = YAML.load(File.read(config_path || File.join(Dir.pwd, 'config', 'cells.yml')))
      Zygote::Web.views = [File.expand_path('../../../views', __FILE__), cells].flatten
      Zygote::Web.cell_config = cell_config
      if debug
        $stdout.sync = true
        $stderr.sync = true
      end

      app = Zygote::Web.new
      dispatch = Rack::Builder.app do
        map '/' do
          run app
        end
      end
      Thin::Logging.trace = true if debug
      @server = Thin::Server.new(port, host, dispatch, threadpool_size: threads).backend
    end

    def start
      @server.start
    rescue => ex
      puts ex
      puts ex.backtrace.join("\n")
    end

    def run
      EM.run do
        init_sighandlers
        @server.start
      end
    end
  end

  def init_sighandlers
    clean_quit = lambda do
      EM.stop
      exit
    end

    Signal.trap('INT') { clean_quit.call }
    Signal.trap('TERM') { clean_quit.call }
  end
end
