require 'redis/distributed'

RSpec.describe ActionDispatch::Session::MultiSessionStore do
  let(:store) { described_class.new :app, redis: redis }
  let(:redis) { instance_spy Redis::Distributed }
  let(:env) { OpenStruct.new params: params }
  let(:params) { {} }

  describe '#initialize' do
    subject(:store) { described_class.new :app, options }
    let(:options) { {} }

    context 'with a :redis option' do
      let(:options) { {redis: redis} }

      it 'takes that as a passed in parameter' do
        expect(store.default_options[:redis]).to eq redis
      end
    end

    context 'with an :expire_after option' do
      let(:options) { {expire_after: 1} }

      it 'persists it in default_options' do
        expect(store.default_options[:expire_after]).to eq 1
      end
    end

    context 'without an :expire_after option' do
      it 'sets its value to @cache.options[:expires_in]' do
        expect(store.default_options[:expire_after]).to eq described_class::DEFAULT_SESSION_EXPIRATION
      end
    end

    context 'with a :param_name option' do
      let(:options) { {param_name: 'my_store_param'} }

      it 'persists it in default_options' do
        expect(store.default_options[:param_name]).to eq 'my_store_param'
      end
    end

    context 'without a :param_name option' do
      it 'persists it in default_options' do
        expect(store.default_options[:param_name]).to eq described_class::DEFAULT_PARAM_NAME
      end
    end

    context 'with a :serializer option' do
      let(:options) { {serializer: Marshal} }

      it 'persists it in default_options' do
        expect(store.default_options[:serializer]).to eq Marshal
      end
    end

    context 'without a :serializer option' do
      it 'persists it in default_options' do
        expect(store.default_options[:serializer]).to eq JSON
      end
    end
  end

  describe '#find_session' do
    subject(:find_session) { store.find_session env, sid }

    before do
      allow(store).to receive(:generate_sid).and_return(:generated_sid)
    end

    context 'without an sid' do
      let(:sid) { nil }

      it 'returns a generated sid and an empty session hash in an array' do
        expect(find_session).to eql([:generated_sid, {}])
      end
    end

    context 'with an sid' do
      let(:sid) { :sid }
      let(:session_data) { {"key" => "value"} }
      let(:serialized_session_data) { session_data.to_json }

      before do
        allow(redis).to receive(:get).with(session_store_key).and_return(serialized_session_data)
      end

      context "and we don't have a subsession ID yet" do
        let(:params) { {} }
        let(:session_store_key) { '_session_id:sid:no_subsession' }

        it 'returns the sid passed in and the corresponding session in an array' do
          expect(find_session).to eq [:sid, session_data]
        end
      end

      context 'and we have a subsession ID' do
        let(:params) { {'subsession_id' => 'subsid'} }
        let(:session_store_key) { '_session_id:sid:subsid' }

        it 'returns the sid passed in and the corresponding session in an array' do
          expect(find_session).to eq [:sid, session_data]
        end

        context 'but there is no session data yet' do
          let(:serialized_session_data) { nil }

          it 'returns the sid passed in and empty session data' do
            expect(find_session).to eq [:sid, {}]
          end
        end
      end
    end
  end

  describe '#write_session' do
    subject(:write_session) { store.write_session(env, :sid, session_data, options) }

    let(:options) { {expire_after: 123} }
    let(:params) { {'subsession_id' => 'subsid'} }
    let(:session_store_key) { '_session_id:sid:subsid' }

    context 'with a session' do
      let(:session_data) { {"key" => "value"} }

      it 'writes the session to the storage' do
        write_session
        expect(redis).to have_received(:set).with(session_store_key, session_data.to_json, ex: 123)
      end

      it 'returns the sid' do
        expect(write_session).to eq :sid
      end
    end

    context 'without a session' do
      let(:session_data) { nil }

      it 'deletes the session from the storage' do
        write_session
        expect(redis).to have_received(:del).with(session_store_key)
      end

      it 'returns the sid' do
        expect(write_session).to eq :sid
      end
    end
  end

  describe '#delete_session' do
    subject(:delete_session) { store.delete_session(env, :sid, :options) }

    let(:params) { {'subsession_id' => 'subsid'} }
    let(:session_store_key) { '_session_id:sid:subsid' }

    it 'deletes the session from the storage' do
      delete_session
      expect(redis).to have_received(:del).with(session_store_key)
    end

    it 'returns the sid' do
      expect(delete_session).to eq :sid
    end
  end

  describe '#validate_sessions' do
    before do
      allow(redis).to receive(:keys).with('_session_id:*').and_return(session_keys)
    end

    let(:session_keys) { sessions.keys }
    let(:sessions) do
      {
        '_session_id:1:1' => {'msid' => 'invalid'},
        '_session_id:1:2' => {'msid' => 'valid'},
        '_session_id:2:1' => {'msid' => 'notvalid'}
      }
    end

    before do
      allow(redis).to receive(:get) { |key| sessions[key].to_json }
    end

    it 'iterates through sessions' do
      memo = []
      store.validate_sessions { |session| memo << session }
      expect(memo).to match_array sessions.values
    end

    it 'deletes the invalid ones' do
      store.validate_sessions { |session| session['msid'] == "valid" }
      expect(redis).to have_received(:del).with('_session_id:1:1')
      expect(redis).to have_received(:del).with('_session_id:2:1')
    end

    context 'when a key is missing during enumeration (e.g. its TTL just expired)' do
      before { allow(redis).to receive(:get).with(session_keys.last).and_return(nil) }

      it 'does not raise error' do
        expect { store.validate_sessions {} }.not_to raise_error
      end

      it 'still deletes the keys found' do
        store.validate_sessions { |session| session['msid'] == "valid" }
        expect(redis).to have_received(:del).with('_session_id:1:1')
      end
    end
  end

  it 'has a version number' do
    expect(MultiSessionStore::VERSION).not_to be nil
  end
end
