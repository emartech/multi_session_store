module MultiSessionStore
  class Railtie < Rails::Railtie
    config.multi_session_store = ActiveSupport::OrderedOptions.new

    initializer 'multi_session_store.add_middleware' do |app|
      app.config.middleware.insert_before ActionDispatch::Session::MultiSessionStore,
                                          MultiSessionStore::SubsessionGeneratorMiddleware,
                                          exclude_paths: app.config.multi_session_store.exclude_paths
    end

    config.to_prepare do
      ApplicationController.prepend MultiSessionStore::DefaultUrlOptions unless ApplicationController.ancestors.include? MultiSessionStore::DefaultUrlOptions
    end
  end
end
