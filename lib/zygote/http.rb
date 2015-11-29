require 'yaml'
require 'json'
require 'genesisreactor'
require 'genesis/protocol/http'
require 'active_support/all'

require 'zygote/util'
require 'zygote/cell_queue'

# Main HTTP class, handles routing methods
# Uses sinatra format (all sinatra docs on routing methods apply)
class ZygoteWeb < Genesis::Http::Handler

  # Requested by iPXE on boot, chains into /boot.
  # This enables us to customize what details we want iPXE to send us
  # The iPXE undionly.kpxe should contain an embedded script to call this URL
  get '/' do
    body { erb :boot }
  end

  # Chainload the primary menu
  get '/chain' do
    # Clean params into a simple hash
    cleaned = clean_params(params.to_h)
    # Add the request ip into the params
    ip = request.ip == '127.0.0.1' ? @env['HTTP_X_FORWARDED_FOR'] : request.ip
    ip = '127.0.0.1' if (ENV['TESTING'] || ip.nil? || ip.empty?)
    cleaned['ip'] = ip
    # Compute SKU from parameters
    sku = compute_sku(cleaned['manufacturer'], cleaned['serial'], cleaned['board-serial'])
    cleaned['sku'] = sku
    # Check if there are is any queued data for this SKU, and if so, merge it in to params
    queued_data = CellQueue.shift(sku)
    cleaned.merge!(queued_data) if queued_data
    @channel << cleaned
    body { erb :menu, locals: { opts: ZygoteWeb::cell_config.merge('params' => cleaned || {}) } }
  end

  # Render an action for a particular cell
  get %r{/cell/(?<cell>\S*)/(?<action>\S*)$} do
    # Clean params into a simple hash
    cleaned = clean_params(params.to_h)
    # Add the cell to the parameters
    cell = cleaned['cell']
    # Merge the cleaned params in with any cell options
    cell_opts = ZygoteWeb::cell_config['index']['cells'][cell] || {}
    opts = cell_opts.merge('params' => cleaned || {})
    @channel << opts # for debugging
    body { erb :"#{cell}/#{cleaned['action']}".to_sym, locals: { opts: opts } }
  end

  # Show the queue for a SKU
  get %r{/queue/(?<sku>\S*)$} do
    body { JSON.pretty_generate(CellQueue.show(params['sku'])) }
  end

  get %r{/queue} do
    response = {}
    CellQueue.all.each do |queue_entry|
      response[queue_entry.name] = queue_entry.data
    end
    body { JSON.pretty_generate(response)}
  end

  # Delete the queue for a SKU
  delete %r{/queue$} do
    CellQueue.purge(params['sku'])
    body { JSON.pretty_generate(CellQueue.show(params['sku'])) }
  end

  post %r{/queue/bulk$} do

    bulk_queue = JSON.parse(request.body.read)
    bulk_queue.each do |asset, queue|
      queue = [queue] unless queue.is_a?(Array)
      queue.each do |action|
        CellQueue.push(asset, action)
      end
    end

    200
  end

  # Enable push cells (with optional data) to the cell queue for a SKU
  post %r{/queue/(?<sku>\S*)/(?<selected_cell>\S*)$} do
    # Clean params into a simple hash
    cleaned = clean_params(params.to_h)
    # Enqueue some data for this sku
    sku = cleaned.delete('sku')
    CellQueue.push(sku, cleaned)
    body { JSON.pretty_generate(CellQueue.show(sku)) }
  end

  subscribe do |args|
    puts args if ENV['DEBUG']
  end

 def ZygoteWeb::cell_config
    @@cell_config
  end

  def ZygoteWeb::cell_config= (value)
    @@cell_config = value
  end
end

def zygote(port: 7000, threads:1000, config_path: nil, cells: [], debug:false)
  debug ||= ENV['DEBUG']

  cell_config= YAML.load(File.read(config_path || File.join(Dir.pwd, 'config', 'cells.yml')))
  ZygoteWeb::cell_config = cell_config
  zygote = Genesis::Reactor.new(
    threads: threads,
    protocols: {
      Genesis::Http::Protocol => port
    },
    handlers: [ZygoteWeb],
    views: [File.expand_path('../../../views', __FILE__), cells ].flatten,
    debug: debug
  )
  if debug
    $stdout.sync = true
    $stderr.sync = true
  end
  zygote
end
