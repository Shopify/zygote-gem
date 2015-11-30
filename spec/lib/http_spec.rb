require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe ZygoteWeb do
  include ZygoteSpec
  include MemorySpec

  context 'render' do
    it 'renders /' do
      match_fixture('ipxe_boot', get('/').response)
    end

    it 'renders /chain' do
      match_fixture('ipxe_menu', get('/chain', MOC_PARAMS['routing']['chain']).response)
    end

    it 'renders /cell/test_os/test' do
      match_fixture('cell_test_action', get('/cell/test_os/test', MOC_PARAMS['routing']['cell_test']).response)
    end
  end

  context 'queues' do
    let(:asset) { 'SPM-1234567' }
    let(:asset2) { 'SPM-2468101214' }
    let(:cell) { 'test' }
    let(:payload) { { 'foo' => 'bar' } }
    let(:count) { 10 }

    def enqueue_data
      (1..count).to_a.each do |i|
        post("/queue/#{asset}/#{cell}", payload.merge('index' => i))
      end
    end

    it 'Is empty for a new asset' do
      expect(JSON.parse(get("/queue/#{asset}").response)).to be_empty
    end

    it 'Enqueues cell data' do
      expect(JSON.parse(post("/queue/#{asset}/#{cell}", payload).response).first).to eq(payload.merge('selected_cell' => cell))
    end

    it 'Queues correct number of actions for cell' do
      enqueue_data
      expect(JSON.parse(get("/queue/#{asset}").response).length).to eq(count)
    end

    it 'Shows ordered cell data' do
      enqueue_data
      expect(JSON.parse(get("/queue/#{asset}").response).first).to eq(payload.merge('selected_cell' => cell, 'index' => 1.to_s))
      expect(JSON.parse(get("/queue/#{asset}").response).last).to eq(payload.merge('selected_cell' => cell, 'index' => count.to_s))
    end

    it 'Can purge the queue' do
      enqueue_data
      expect(JSON.parse(delete("/queue?sku=#{asset}").response)).to be_empty
      expect(JSON.parse(get("/queue/#{asset}").response)).to be_empty
    end

    it 'Shows all assets in the queue' do
      post("/queue/#{asset}/#{cell}", payload)
      post("/queue/#{asset2}/#{cell}", payload)

      response = JSON.parse(get('/queue').response)
      expect(response.length).to eq(2)
      expect(response[asset]).to_not be_nil
      expect(response[asset2]).to_not be_nil
    end

    it 'can do a bulk queue' do
      bulk_queue = {
        asset => payload.merge('selected_cell' => cell, 'index' => '1'),
        asset2 => [
          payload.merge('selected_cell' => 'burnin', 'index' => '1'),
          payload.merge('selected_cell' => 'default ubuntu', 'index' => '2')
        ]
      }
      post('/queue/bulk', bulk_queue.to_json)

      expect(JSON.parse(get("/queue/#{asset}").response).first).to eq(payload.merge('selected_cell' => cell, 'index' => 1.to_s))
      expect(JSON.parse(get("/queue/#{asset2}").response).first).to eq(payload.merge('selected_cell' => 'burnin', 'index' => 1.to_s))
    end

    # Can render default entries
    it 'Pops the queue onto /chain' do
      (1..count).to_a.each do |i|
        post("/queue/#{asset}/#{cell}", payload.merge('index' => i))
      end
      (1..count).to_a.each do |i|
        menu = get('/chain', manufacturer: 'Supermicro', serial: '1234567').response
        expect(menu).to include(payload.merge('index' => i).to_query)
        expect(menu).to include("goto #{payload['select_cell']}")
      end
      expect(JSON.parse(get("/queue/#{asset}").response)).to be_empty
    end
  end

  context 'menu' do

    it 'can render top level menus' do
      rendered_menu = get('/chain', MOC_PARAMS['routing']['chain']).response
      ZygoteWeb.cell_config['index']['cells'].each do |menu, data|
        symbol = data['menu']['submenu'] ? "submenu-#{menu}" : menu
        expect(rendered_menu).to match(/^item --key #{menu[0]} #{symbol} #{data['menu']['label']}$/)
      end
    end

    it 'can render menus chains' do
      rendered_menu = get('/chain', MOC_PARAMS['routing']['chain']).response
      ZygoteWeb.cell_config['index']['cells'].each do |menu, data|
        unless data['menu']['submenu']
          expect(rendered_menu).to match(/:#{menu}\nchain --replace --autofree\s+http:\/\/\${dhcp-server}\/cell\/#{menu}\/#{data['action'] || 'boot'}/m)
        end
      end
    end

    it 'can render top level menus by class' do
      rendered_menu = get('/chain', MOC_PARAMS['routing']['chain']).response
      ZygoteWeb.cell_config['index']['cells'].each do |menu, data|
        symbol = data['menu']['submenu'] ? "submenu-#{menu}" : menu
        expect(rendered_menu).to match(/OS Installation.*item --key #{menu[0]} #{symbol} #{data['menu']['label']}/m) if data['menu']['class'] == 'os'
        expect(rendered_menu).to match(/Tools and utilities.*item --key #{menu[0]} #{symbol} #{data['menu']['label']}/m) if data['menu']['class'] == 'util'
      end
    end
  end

  context 'submenus' do
    it 'can render submenus' do
      rendered_menu = get('/chain', MOC_PARAMS['routing']['chain']).response
      ZygoteWeb.cell_config['index']['cells'].each do |menu, data|
        if data['menu']['submenu']
          symbol = data['menu']['submenu'] ? "submenu-#{menu}" : menu
          expect(rendered_menu).to match(/OS Installation.*item --key #{menu[0]} #{symbol} #{data['menu']['label']}/m) if data['menu']['class'] == 'os'
          expect(rendered_menu).to match(/Tools and utilities.*item --key #{menu[0]} #{symbol} #{data['menu']['label']}/m) if data['menu']['class'] == 'util'
          expect(rendered_menu).to match(/^:submenu-#{menu}\nmenu #{data['menu']['label']}/)
          data['menu']['submenu'].each do |entry, subdata|
            expect(rendered_menu).to match(/^item\s+#{menu}-#{entry}\s+#{subdata['label']}/)
          end
        end
      end
    end

    it 'can render submenu chains' do
      rendered_menu = get('/chain', MOC_PARAMS['routing']['chain']).response
      ZygoteWeb.cell_config['index']['cells'].each do |menu, data|
        data['menu']['submenu'].each do |entry, subdata|
          expect(rendered_menu).to match(/:#{menu}-#{entry}\nchain --replace --autofree\s+http:\/\/\${dhcp-server}\/cell\/#{menu}\/#{subdata['action'] || 'boot'}/m)
        end if data['menu']['submenu']
      end
    end

  end
end
