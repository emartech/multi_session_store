require 'securerandom'

module MultiSessionStore
  class SubsessionGeneratorMiddleware
    def initialize(app, config = {})
      @app = app
      @config = config
    end

    def call(env)
      request = Rack::Request.new(env)
      request.update_param 'subsession_id', new_subsession_id if subsession_id_is_needed?(request)
      @app.call(env)
    end

    private

    def new_subsession_id
      SecureRandom.hex
    end

    def subsession_id_is_needed?(request)
      !request.params['subsession_id'] && !path_excluded?(request.path)
    end

    def path_excluded?(current_path)
      excluded_paths.any? { |excluded_path| excluded_path.match? current_path }
    end

    def excluded_paths
      @config[:exclude_path] ||= []
    end
  end
end
