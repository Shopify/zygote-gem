require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe Memory do
  include MemorySpec

  context 'database' do
    it 'loads the database' do
      expect(Memory.load).to be true
    end

    it 'saves the database' do
      expect(Memory.save).to be true
    end
  end
end
