require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe Zygote::Identifier do
  let(:params) { {foo: 'bar', spam: 'eggs'} }

  context 'not subclassed' do
    it 'returns the params provided to it' do
      expect(Zygote::Identifier.identify(params)).to eq(params)
    end
  end

  context 'subclassed' do

    it "mutates the params using the subclass's identify" do

      class MyIdentify < Zygote::Identifier
        def identify
          @params.merge(id: 'myidentify')
        end
      end

      expect(Zygote::Identifier.identify(params)).to eq(params.merge(id: 'myidentify'))
    end
  end
end
