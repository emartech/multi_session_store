module MultiSessionStore
  class Railtie < Rails::Railtie
    config.multi_session_store = ActiveSupport::OrderedOptions.new

    initializer 'multi_session_store.add_middleware' do |app|
      app.config.middleware.use MultiSessionStore::SubsessionGeneratorMiddleware, exclude_path: app.config.multi_session_store.exclude_path
    end
  end
end
