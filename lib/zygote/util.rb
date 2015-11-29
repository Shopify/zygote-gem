require 'socket'

def compute_sku(vendor, serial, board_serial)
  # Sanitize params
  strip_pattern = /[^-^:\p{Alnum}]/
  serial        = (serial || '').gsub(strip_pattern, '')
  vendor        = (vendor || '').gsub(strip_pattern, '')
  board_serial  = (board_serial || '').gsub(strip_pattern, '')

  serial = board_serial unless board_serial.empty?

  case vendor
  when 'DellInc'
    sku = 'DEL'
  when 'Supermicro'
    sku = 'SPM'
  else
    sku = 'UKN' # unknown manufacturer
  end

  sku = "#{sku}-#{serial}"
  sku
end

def clean_params(params)
  params.delete_if { |x, _| x == 'splat' || x == 'captures' }
  params
end

def my_ip
  Socket.ip_address_list.find{|x| x.ipv4? && !x.ipv4_loopback?}.ip_address
end

def discover_domain
  Socket.gethostname.split('.')[1..-1].join('.')
end
