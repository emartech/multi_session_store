module MultiSessionStore
  class Railtie < Rails::Railtie
    config.multi_session_store = ActiveSupport::OrderedOptions.new

    initializer 'multi_session_store.add_middleware' do |app|
      app.config.middleware.insert_before ActionDispatch::Session::MultiSessionStore,
                                          MultiSessionStore::SubsessionGeneratorMiddleware,
                                          exclude_paths: app.config.multi_session_store.exclude_paths
    end

    config.after_initialize do
      ApplicationController.prepend MultiSessionStore::DefaultUrlOptions
    end
  end
end
