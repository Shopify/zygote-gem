require 'socket'
require 'base64'
require 'json'

def compute_sku(vendor, serial, board_serial)
  # Sanitize params
  strip_pattern = /[^-^:\p{Alnum}]/
  serial        = (serial || '').gsub(strip_pattern, '')
  vendor        = (vendor || '').gsub(strip_pattern, '')
  board_serial  = (board_serial || '').gsub(strip_pattern, '')

  serial = board_serial unless board_serial.empty?

  sku = case vendor
        when 'DellInc'
          'DEL'
        when 'Supermicro'
          'SPM'
        else
          'UKN' # unknown manufacturer
        end

  sku = "#{sku}-#{serial}"
  sku
end

def clean_params(params)
  params.delete_if { |x, _| x == 'splat' || x == 'captures' }
  params = params.map { |k, v| [k, v.is_a?(Hash) ? encode64(v) : v] }.to_h
  params
end

def encode64(content)
  Base64.encode64(JSON.pretty_generate(content)).gsub(/\n|=/, '')
end

def decode64(content)
  JSON.load(Base64.decode64(content))
end

def my_ip
  Socket.ip_address_list.find { |x| x.ipv4? && !x.ipv4_loopback? }.ip_address
end

def discover_domain
  Socket.gethostname.split('.')[1..-1].join('.')
end

def kernel_params(hash)
  hash.map do |k, v|
    if v.is_a? Array
      v.map { |x| "#{k}=#{x}" }
    else
      "#{k}=#{v}"
    end
  end.join(' ')
end
