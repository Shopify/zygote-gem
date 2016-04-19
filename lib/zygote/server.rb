require 'zygote/http'
require 'thin'

class ZygoteServer
  def initialize(port: 7000, threads:1000, host: '0.0.0.0', config_path: nil, cells: [], debug:false)
    debug ||= ENV['DEBUG']

    cell_config = YAML.load(File.read(config_path || File.join(Dir.pwd, 'config', 'cells.yml')))
    ZygoteWeb.views = [File.expand_path('../../../views', __FILE__), cells].flatten
    ZygoteWeb.cell_config = cell_config
    if debug
      $stdout.sync = true
      $stderr.sync = true
    end

    app = ZygoteWeb.new
    dispatch = Rack::Builder.app do
      map '/' do
        run app
      end
    end
    Thin::Logging.trace=true if debug
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
  trap(:INT)  { 'Got interrupt'; EM.stop; exit }
  trap(:TERM) { 'Got term';      EM.stop; exit }
  trap(:KILL) { 'Got kill';      EM.stop; exit }
end
