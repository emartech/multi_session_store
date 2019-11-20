require "multi_session_store/version"
require "multi_session_store/subsession_generator_middleware"
require "multi_session_store/default_url_options"
require "multi_session_store/railtie" if defined? Rails
require "action_dispatch"
require 'json'

module ActionDispatch
  module Session
    class MultiSessionStore < AbstractStore
      DEFAULT_SESSION_EXPIRATION = 24 * 60 * 60

      def initialize(app, options = {})
        options[:expire_after] ||= DEFAULT_SESSION_EXPIRATION
        options[:param_name] ||= 'subsession_id'
        options[:serializer] ||= JSON
        @redis = options[:redis]
        @param_name = options[:param_name]
        @serializer = options[:serializer]
        super
      end

      def find_session(env, sid)
        if sid
          serialized_session_data = @redis.get session_store_key(env, sid)
          session_data = serialized_session_data ? @serializer.parse(serialized_session_data) : {}
          [sid, session_data]
        else
          [generate_sid, {}]
        end
      end

      def write_session(env, sid, session, options)
        key = session_store_key env, sid
        if session
          @redis.set key, @serializer.dump(session), ex: options[:expire_after]
        else
          @redis.del key
        end
        sid
      end

      def delete_session(env, sid, options)
        @redis.del session_store_key(env, sid)
        sid
      end

      private

      def session_store_key(env, sid)
        subsession_id = env.params[@param_name] || 'no_subsession'
        "_session_id:#{sid}:#{subsession_id}"
      end
    end
  end
end
