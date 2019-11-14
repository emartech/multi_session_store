RSpec.describe ActionDispatch::Session::MultiSessionStore do
  describe '#initialize' do
    context 'with a :cache option' do
      subject do
        ActionDispatch::Session::MultiSessionStore.new(:app, { cache: cache } )
      end

      let(:cache) do
        OpenStruct.new(options: {})
      end

      it 'takes that as a passed in parameter' do
        expect(subject.default_options[:cache]).to eql(cache)
      end
    end

    context 'with an :expire_after option' do
      subject(:multisession) { ActionDispatch::Session::MultiSessionStore.new(:app, { expire_after: 1 }) }

      it 'persists it in default_options' do
        expect(multisession.default_options[:expire_after]).to eq 1
      end
    end

    context 'without an :expire_after option' do
      subject(:multisession) { ActionDispatch::Session::MultiSessionStore.new(:app, { cache: cache }) }

      let(:cache) do
        OpenStruct.new(options: { expires_in: 123 })
      end

      it 'sets its value to @cache.options[:expires_in]' do
        expect(multisession.default_options[:expire_after]).to eql(123)
      end
    end

    context 'with a param option' do
      subject(:multisession) { ActionDispatch::Session::MultiSessionStore.new(:app, { expire_after: 1, param: 'my_store_param' }) }

      it 'persists it in default_options' do
        expect(multisession.default_options[:param]).to eql('my_store_param')
      end
    end

    context 'with a serializer option' do
      subject(:multisession) { ActionDispatch::Session::MultiSessionStore.new(:app, { expire_after: 1, serializer: 'JSON' }) }

      it 'persists it in default_options' do
        expect(multisession.default_options[:serializer]).to eql('JSON')
      end
    end
  end

  it "has a version number" do
    expect(MultiSessionStore::VERSION).not_to be nil
  end
end
