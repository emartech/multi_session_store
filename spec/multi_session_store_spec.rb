RSpec.describe ActionDispatch::Session::MultiSessionStore do
  let(:cache) { double('Cache', options: cache_options) }
  let(:cache_options) { {} }

  describe '#initialize' do
    context 'with a :cache option' do
      subject do
        ActionDispatch::Session::MultiSessionStore.new(:app, { cache: cache } )
      end

      it 'takes that as a passed in parameter' do
        expect(subject.default_options[:cache]).to eql(cache)
      end
    end

    context 'with an :expire_after option' do
      subject(:store) { ActionDispatch::Session::MultiSessionStore.new(:app, { expire_after: 1 }) }

      it 'persists it in default_options' do
        expect(store.default_options[:expire_after]).to eq 1
      end
    end

    context 'without an :expire_after option' do
      subject(:store) { ActionDispatch::Session::MultiSessionStore.new(:app, { cache: cache }) }

      let(:cache_options) { {expires_in: 123} }

      it 'sets its value to @cache.options[:expires_in]' do
        expect(store.default_options[:expire_after]).to eql(123)
      end
    end

    context 'with a param option' do
      subject(:store) { ActionDispatch::Session::MultiSessionStore.new(:app, { expire_after: 1, param: 'my_store_param' }) }

      it 'persists it in default_options' do
        expect(store.default_options[:param]).to eql('my_store_param')
      end
    end

    context 'with a serializer option' do
      subject(:store) { ActionDispatch::Session::MultiSessionStore.new(:app, { expire_after: 1, serializer: 'JSON' }) }

      it 'persists it in default_options' do
        expect(store.default_options[:serializer]).to eql('JSON')
      end
    end
  end

  describe '#find_session' do
    let(:store) do
      ActionDispatch::Session::MultiSessionStore.new(:app, expires_after: 1, cache: cache, serializer: serializer)
    end

    context 'without an sid' do
      let(:serializer) { double('Serializer') }
      let(:cache_key) { '_session_id:123:1234' }

      before do
        expect(store).to receive(:generate_sid).and_return(:generated_sid)
        expect(store).to receive(:cache_key).with(:env, :generated_sid).and_return(cache_key)
        expect(cache).to receive(:read).with(cache_key).and_return(:cache_content)
        expect(serializer).to receive(:parse).with(:cache_content).and_return(:session)
      end

      it 'returns a generated sid and a session in an array' do
        expect(store.find_session(:env, nil)).to eql([:generated_sid, :session])
      end
    end

    context 'with an sid' do
      let(:serializer) { double('Serializer') }
      let(:cache_key) { '_session_id:123:1234' }

      before do
        expect(store).to receive(:cache_key).with(:env, :sid).and_return(cache_key)
        expect(cache).to receive(:read).with(cache_key).and_return(:cache_content)
        expect(serializer).to receive(:parse).with(:cache_content).and_return(:session)
      end

      it 'returns the sid passed in and a session in an array' do
        expect(store.find_session(:env, :sid)).to eql([:sid, :session])
      end
    end
  end

  describe '#write_session' do
    let(:store) do
      ActionDispatch::Session::MultiSessionStore.new(:app, expires_after: 1, cache: cache, serializer: serializer)
    end

    subject(:write_session) { store.write_session(:env, :sid, session, options) }

    let(:options) { {expire_after: 123} }
    let(:serializer) { double('Serializer') }

    before do
      expect(store).to receive(:cache_key).with(:env, :sid).and_return(:key)
    end

    context 'with a session' do
      let(:session) { :session }

      before do
        expect(serializer).to receive(:dump).with(:session).and_return(:serialized_session)
        expect(cache).to receive(:write).with(:key, :serialized_session, expires_in: 123)
      end

      it 'writes to the cache and returns sid' do
        expect(write_session).to eq(:sid)
      end
    end

    context 'without a session' do
      let(:session) { nil }

      before do
        expect(cache).to receive(:delete).with(:key)
      end

      it 'deletes from the cache and returns sid' do
        expect(write_session).to eq(:sid)
      end
    end
  end

  describe '#delete_session' do
    let(:store) do
      ActionDispatch::Session::MultiSessionStore.new(:app, expires_after: 1, cache: cache)
    end

    subject(:delete_session) { store.delete_session(:env, :sid, :options) }

    before do
      expect(store).to receive(:cache_key).with(:env, :sid).and_return(:cache_key)
      expect(cache).to receive(:delete).with(:cache_key)
    end

    it 'deletes from cache and return the sid' do
      expect(delete_session).to eq(:sid)
    end
  end

  it "has a version number" do
    expect(MultiSessionStore::VERSION).not_to be nil
  end
end
