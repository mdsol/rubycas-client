require 'action_dispatch/middleware/session/abstract_store'
require 'redis'
require 'redis-store'
require 'redis-activesupport'
require 'redis-actionpack'

module ActionDispatch
  module Session
    # A session store that uses an ActiveSupport::Cache::Store to store the sessions. This store is most useful
    # if you don't store critical data in your sessions and you don't need them to live for extended periods
    # of time.
    #
    # ==== Options
    # * <tt>cache</tt>         - The cache to use. If it is not specified, <tt>Rails.cache</tt> will be used.
    # * <tt>expire_after</tt>  - The length of time a session will be stored before automatically expiring.
    #   By default, the <tt>:expires_in</tt> option of the cache is used.
    class ActiveModelRedisStore < ActionDispatch::Session::RedisStore

      def get_session(env, sid)
        super(env,sid)
      end

      def set_session(env, sid, new_session, options)
        session = self.get_session(env,sid)[1]
        unless session.nil?
          # Copy session_id and service_ticket into the session_data
          %w(sid service_ticket).each { |key| new_session[key] = session[key] if session[key] }
        end
        super(env, sid, new_session, options)
      end

      # The service ticket is also being stored in Redis in the form -
      # service_ticket => session_id
      # session_id => {session_data}
      # Need to ensure that when a session is being destroyed - we also clean up the service-ticket
      # related data prior to letting the session be destroyed.
      def destroy_session(env, session_id, options)
        session = self.get_session(env,session_id)[1]
        if session.present?
          begin
            with_lock(env, [nil, {}]) do
              last_st = if sesh = get_session_with_fallback(session_id)
                          sesh['cas_last_valid_ticket']
                        end

              with do |c|
                Rails.logger.info "deleting service-ticket with key #{"#{options[:namespace]}:#{last_st}"}"
                [last_st, session_id].each do |t|
                  c.del([options[:namespace], t].compact.join(':'))
                end
              end
            end
          rescue => e
            Rails.logger.info "Error cleaning up cas cache data: #{e}"
          end
          super(env, session_id, options)
        else
          CASClient::LoggerWrapper.new.warn("Session::ActiveModelRedisStore#destroy_session: the retrieved pool session for session_id #{session_id} is nil");
        end
      end

      # Patch Rack 2.0 changes that broke ActionDispatch.
      alias_method :find_session, :get_session
      alias_method :write_session, :set_session
      alias_method :delete_session, :destroy_session

    end
  end
end

module ActiveSupport
  module Cache
    class RedisCacheStore
    end
  end
end
