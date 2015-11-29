require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe CellQueue do
  include MemorySpec

  let(:count) { 100 }
  let(:passes) { 10 }
  let(:sample_data) { { 'foo' => 'bar' } }
  let(:sample_data2) { { 'foo' => 'baz' } }
  let(:asset) { 'SPM-1234567' }
  let(:asset2) { 'SPM-2468101214' }

  it 'pushes values' do
    expect(CellQueue.show(asset)).to be_empty
    CellQueue.push(asset, sample_data)
    expect(CellQueue.show(asset).length).to eq(1)
  end

  it 'shifts values' do
    expect(CellQueue.show(asset)).to be_empty
    CellQueue.push(asset, sample_data)
    expect(CellQueue.show(asset).length).to eq(1)
    entry = CellQueue.shift(asset)
    expect(entry).to eq(sample_data)
    expect(CellQueue.show(asset)).to be_empty
  end

  it 'shifts nil on empty' do
    expect(CellQueue.show(asset)).to be_empty
    expect(CellQueue.shift(asset)).to be_nil
  end

  it 'returns all values on queue' do
    CellQueue.push(asset, sample_data)
    CellQueue.push(asset2, sample_data2)

    all_elements = CellQueue.all
    expect(all_elements.length).to eq(2)

    expect(all_elements[0].name).not_to eq(all_elements[1].name)
  end
end
