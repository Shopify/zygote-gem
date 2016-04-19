require 'yaml'
require 'json'

require 'active_support/all'
require 'sinatra/async'
require 'tilt/erubis'
require 'rack/contrib'

require 'zygote/util'
require 'zygote/cell_queue'

# Main HTTP class, handles routing methods
# Uses sinatra format (all sinatra docs on routing methods apply)
class ZygoteWeb < Sinatra::Base
  register Sinatra::Async

  use ::Rack::PostBodyContentTypeParser
  set :show_exceptions, ENV['DEBUG'] || false
  # Requested by iPXE on boot, chains into /boot.
  # This enables us to customize what details we want iPXE to send us
  # The iPXE undionly.kpxe should contain an embedded script to call this URL
  aget '/' do
    body { erb :boot }
  end

  # Chainload the primary menu
  aget '/chain' do
    # Clean params into a simple hash
    cleaned = clean_params(params.to_h)
    # Add the request ip into the params
    ip = request.ip == '127.0.0.1' ? @env['HTTP_X_FORWARDED_FOR'] : request.ip
    ip = '127.0.0.1' if ENV['TESTING'] || ip.nil? || ip.empty?
    cleaned['ip'] = ip
    # Compute SKU from parameters
    sku = compute_sku(cleaned['manufacturer'], cleaned['serial'], cleaned['board-serial'])
    cleaned['sku'] = sku
    # Check if there are is any queued data for this SKU, and if so, merge it in to params
    queued_data = CellQueue.shift(sku)
    cleaned.merge!(queued_data) if queued_data
    body { erb :menu, locals: { opts: ZygoteWeb.cell_config.merge('params' => cleaned || {}) } }
  end

  [ :aget, :apost ].each do |method|
    send method, %r{/cell/(?<cell>\S*)/(?<action>\S*)$} do
      # Render an action for a particular cell
      # Clean params into a simple hash
      cleaned = clean_params(params.to_h)
      # Add the cell to the parameters
      cell = cleaned['cell']
      # Merge the cleaned params in with any cell options
      cell_opts = ZygoteWeb.cell_config['index']['cells'][cell] || {}
      opts = cell_opts.merge('params' => cleaned || {})
      body { erb :"#{cell}/#{cleaned['action']}".to_sym, locals: { opts: opts } }
    end
  end

  # Show the queue for a SKU
  aget %r{/queue/(?<sku>\S*)$} do
    body { JSON.pretty_generate(CellQueue.show(params['sku'])) }
  end

  aget %r{/queue} do
    response = {}
    CellQueue.all.each do |queue_entry|
      response[queue_entry.name] = queue_entry.data
    end
    body { JSON.pretty_generate(response) }
  end

  # Delete the queue for a SKU
  adelete %r{/queue$} do
    CellQueue.purge(params['sku'])
    body { JSON.pretty_generate(CellQueue.show(params['sku'])) }
  end

  apost %r{/queue/bulk$} do
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
  apost %r{/queue/(?<sku>\S*)/(?<selected_cell>\S*)$} do
    # Clean params into a simple hash
    cleaned = clean_params(params.to_h)
    # Enqueue some data for this sku
    sku = cleaned.delete('sku')
    CellQueue.push(sku, cleaned)
    body { JSON.pretty_generate(CellQueue.show(sku)) }
  end

  def self::cell_config
    @@cell_config
   end

  def self::cell_config=(value)
    @@cell_config = value
  end

  def self::views
    @@views
   end

  def self::views=(value)
    @@views = value
  end

  helpers do
    # Enable partial template rendering
    def partial(template, locals = {})
      erb(template, layout: false, locals: locals)
    end

    # Override template search directorys to add spells
    def find_template(_views, *a, &block)
      Array(ZygoteWeb.views).each { |v| super(v, *a, &block) }
    end

    # Define our asynchronous scheduling mechanism, could be anything
    # Chose EM.defer for simplicity
    # This powers our asynchronous requests, and keeps us from blocking the main thread.
    def native_async_schedule(&b)
      EM.defer(&b)
    end

    # Needed to properly catch exceptions in async threads
    def handle_exception!(context)
      if context.message == 'Sinatra::NotFound'
        error_msg = "Resource #{request.path} does not exist"
        puts error_msg
        ahalt(404, error_msg)
      else
        puts context.message
        puts context.backtrace.join("\n")
        ahalt(500, 'Uncaught exception occurred')
      end
    end
  end
end
