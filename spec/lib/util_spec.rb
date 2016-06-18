require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe 'utility class' do
  it 'cleans params' do
    myhash = { 'wanted' => 'yes', 'splat' => 'no', 'captures' => 'no' }
    cleaned = clean_params(myhash)
    expect(cleaned.keys).to eq(['wanted'])
    expect(cleaned.length).to eq(1)
  end

  context 'skus' do
    let(:dell) { 'Dell Inc.' }
    let(:supermicro) { 'Supermicro' }
    let(:unknown) { 'Hewlett Packard' }
    let(:serial) { '8B204D563EA5' }
    let(:board) { 'FEFF819CDC9F' }

    it 'computes dell skus' do
      expect(compute_sku(dell, serial, board)).to eq("DEL-#{board}")
    end

    it 'computes supermicro skus' do
      expect(compute_sku(supermicro, serial, board)).to eq("SPM-#{board}")
    end

    it 'computes unknown skus' do
      expect(compute_sku(unknown, serial, board)).to eq("UKN-#{board}")
    end

    it 'prefers board serial' do
      expect(compute_sku(supermicro, serial, board)).to eq("SPM-#{board}")
    end

    it 'falls back to system serial' do
      expect(compute_sku(supermicro, serial, '')).to eq("SPM-#{serial}")
    end
  end

  context 'kernel params' do
    let(:keyvalue) { { 'boot' => 'live', 'root' => '/dev/ram0' } }
    let(:list) { { 'console' => ['tty0', 'ttyS1' ]} }

    it 'maps hashes' do
      expect(kernel_params(keyvalue)).to eq('boot=live root=/dev/ram0')
    end

    it 'handles hashes and lists' do
      expect(kernel_params(keyvalue.merge(list))).to eq('boot=live root=/dev/ram0 console=tty0 console=ttyS1')
    end
  end
end
