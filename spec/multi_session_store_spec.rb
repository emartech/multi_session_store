require 'redis/distributed'

RSpec.describe ActionDispatch::Session::MultiSessionStore do
  subject(:store) { described_class.new(:app, redis: redis, serializer: serializer) }
  let(:redis) { instance_spy Redis::Distributed }
  let(:serializer) { double 'Serializer' }
  let(:env) { OpenStruct.new params: params }
  let(:params) { {} }

  describe '#initialize' do
    subject(:store) { described_class.new(:app, options) }
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

    context 'with a param_name option' do
      let(:options) { {param_name: 'my_store_param'} }

      it 'persists it in default_options' do
        expect(store.default_options[:param_name]).to eq 'my_store_param'
      end
    end

    context 'without a param_name option' do
      it 'persists it in default_options' do
        expect(store.default_options[:param_name]).to eq 'subsession_id'
      end
    end

    context 'with a serializer option' do
      let(:options) { {serializer: 'JSON'} }

      it 'persists it in default_options' do
        expect(store.default_options[:serializer]).to eq 'JSON'
      end
    end
  end

  describe '#find_session' do
    before do
      allow(store).to receive(:generate_sid).and_return(:generated_sid)
    end

    context 'without an sid' do
      it 'returns a generated sid and an empty session hash in an array' do
        expect(store.find_session(:env, nil)).to eql([:generated_sid, {}])
      end
    end

    context 'with an sid' do
      subject(:find_session) { store.find_session env, :sid }

      before do
        allow(redis).to receive(:get).with(session_store_key).and_return(:serialized_session_data)
        allow(serializer).to receive(:parse).with(:serialized_session_data).and_return(:session_data)
      end

      context "and we don't have a subsession ID yet" do
        let(:params) { {} }
        let(:session_store_key) { '_session_id:sid:no_subsession' }

        it 'returns the sid passed in and the corresponding session in an array' do
          expect(find_session).to eq [:sid, :session_data]
        end
      end

      context 'and we have a subsession ID' do
        let(:params) { {'subsession_id' => 'subsid'} }
        let(:session_store_key) { '_session_id:sid:subsid' }

        it 'returns the sid passed in and the corresponding session in an array' do
          expect(find_session).to eq [:sid, :session_data]
        end
      end
    end
  end

  describe '#write_session' do
    subject(:write_session) { store.write_session(env, :sid, session, options) }
    let(:options) { {expire_after: 123} }
    let(:params) { {'subsession_id' => 'subsid'} }
    let(:session_store_key) { '_session_id:sid:subsid' }

    context 'with a session' do
      let(:session) { :session_data }

      before do
        allow(serializer).to receive(:dump).with(:session_data).and_return(:serialized_session_data)
      end

      it 'writes the session to the storage' do
        write_session
        expect(redis).to have_received(:set).with(session_store_key, :serialized_session_data, ex: 123)
      end

      it 'returns the sid' do
        expect(write_session).to eq :sid
      end
    end

    context 'without a session' do
      let(:session) { nil }

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

  it "has a version number" do
    expect(MultiSessionStore::VERSION).not_to be nil
  end
end
