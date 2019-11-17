RSpec.describe MultiSessionStore::SubsessionGeneratorMiddleware do
  subject(:middleware) { described_class.new app, config }
  let(:app) { double 'application' }
  let(:config) { {} }

  describe '#call' do
    subject(:call) { middleware.call env }
    let(:call_result) { 'status, headers and body' }
    let(:env) do
      {
        'REQUEST_METHOD' => 'GET',
        'QUERY_STRING' => query_string,
        'PATH_INFO' => '/healthcheck',
        'action_dispatch.remote_ip' => '127.0.0.1',
        'rack.input' => StringIO.new('')
      }
    end
    let(:query_string) { '' }
    let(:request) { Rack::Request.new env }

    before do
      allow(app).to receive(:call).with(env).and_return(call_result)
    end

    it 'calls the next middleware in the stack and returns the results' do
      expect(call).to eq call_result
    end

    it 'generates a subsession ID into the request' do
      allow(SecureRandom).to receive(:hex).and_return('subsession_ID_hash')
      call
      expect(request.params).to include 'subsession_id' => 'subsession_ID_hash'
    end

    context 'when the request already contains a subsession ID' do
      let(:query_string) { 'subsession_id=subsession_ID_hash' }

      it 'does not overwrite the existing ID' do
        call
        expect(request.params).to include 'subsession_id' => 'subsession_ID_hash'
      end
    end

    context 'when the path is excluded from subsession management' do
      let(:config) { {exclude_paths: ['/some_path', '/healthcheck']} }

      it 'does not generate a subsession ID into the request' do
        call
        expect(request.params).not_to include 'subsession_id'
      end

      context 'and the exclude path is a regexp' do
        let(:config) { {exclude_paths: [%r'/health.*']} }

        it 'does not generate a subsession ID into the request' do
          call
          expect(request.params).not_to include 'subsession_id'
        end
      end
    end
  end
end
