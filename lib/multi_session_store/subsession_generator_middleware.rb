require 'securerandom'

module MultiSessionStore
  class SubsessionGeneratorMiddleware
    def initialize(app, config = {})
      @app = app
      @config = config
    end

    def call(env)
      request = Rack::Request.new(env)
      set_subsession_id_from_header(request)
      generate_subsession_id_if_needed(request)
      @app.call(env)
    end

    private

    SUBSESSION_ID_HEADER = 'HTTP_X_SUBSESSIONID'.freeze

    def set_subsession_id_from_header(request)
      request.update_param 'subsession_id', request.get_header(SUBSESSION_ID_HEADER) if request.has_header?(SUBSESSION_ID_HEADER)
    end

    def generate_subsession_id_if_needed(request)
      request.update_param 'subsession_id', new_subsession_id if subsession_id_is_needed?(request)
    end

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
      @config[:exclude_paths] ||= []
    end
  end
end
