RSpec.describe MultiSessionStore::DefaultUrlOptions do
  let(:controller_class) { Class.new }
  let(:controller) { controller_class.new }
  let(:params_hash) { {} }

  before do
    controller_class.class_eval "def params; #{params_hash}; end"
  end

  describe '#default_url_options' do
    subject(:default_url_options) do
      controller_class.prepend MultiSessionStore::DefaultUrlOptions
      controller.default_url_options
    end

    it 'returns an empty hash' do
      expect(default_url_options).to eq({})
    end

    context 'when params has a subsession_id' do
      let(:params_hash) { {subsession_id: 'subsession ID hash'} }

      it 'contains the subsession_id' do
        expect(default_url_options).to eq(subsession_id: 'subsession ID hash')
      end
    end

    context 'when controller already has default_url_options' do
      let(:params_hash) { {subsession_id: 'subsession ID hash'} }
      before do
        controller_class.class_eval "def default_url_options; {previous: 'option'}; end"
      end

      it 'keeps the previously defined options and adds the subsession ID' do
        expect(default_url_options).to eq(previous: 'option',
                                          subsession_id: 'subsession ID hash')
      end
    end
  end
end
