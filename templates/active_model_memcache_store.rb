require 'action_dispatch/middleware/session/abstract_store'
require 'action_dispatch/middleware/session/dalli_store'

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
    class ActiveModelMemcacheStore < ActionDispatch::Session::DalliStore

      def set_session(env, sid, session_data, options = nil)
        if @pool.exist?(sid)
          session = @pool.get(sid)
          # Only store the session_id and service_ticket key-value pairs in the session_data
          updated_session = {}
          updated_session.merge!("session_id" => session['session_id']) if session['session_id']
          updated_session.merge!("service_ticket" => session['service_ticket']) if session['service_ticket']
          session_data.merge!(updated_session) if updated_session.present?
        end
        super(env, sid, session_data, options)
      end

      # The service ticket is also being stored in Memcache in the form -
      # service_ticket => session_id
      # session_id => {session_data}
      # Need to ensure that when a session is being destroyed - we also clean up the service-ticket 
      # related data prior to letting the session be destroyed.
      def destroy_session(env, session_id, options)
        if @pool.exist?(session_id)
          session = @pool.get(session_id)
            if session.has_key?("service_ticket") && @pool.exist?(session["service_ticket"])
              begin
                @pool.delete(session["service_ticket"])
              rescue Dalli::DalliError
                CASClient::LoggerWrapper.new.warn("Session::DalliStore#destroy_session: #{$!.message}");
                raise if @raise_errors
              end
            else
              CASClient::LoggerWrapper.new.warn("Session::ActiveModelMemcacheStore#destroy_session: Session  #{session_id} has_key?: #{session.has_key?("service_ticket")}, @pool.exist?: #{@pool.exist?(session["service_ticket"])}");
            end
        end
        super(env, session_id, options)
      end

    end
  end
end


module ActiveSupport
  module Cache
    class DalliStore
      alias_method :get, :read
      alias_method :set, :write
    end
  end
end
