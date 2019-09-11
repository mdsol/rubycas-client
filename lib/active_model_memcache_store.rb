require 'action_dispatch/middleware/session/abstract_store'
require 'action_dispatch/middleware/session/dalli_store'
require 'active_support/cache/dalli_store.rb'

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
        puts '----------------------------set_session'
        if @pool.exist?(sid)
          session = @pool.get(sid)
          # Copy session_id and service_ticket into the session_data
          %w(session_id service_ticket).each { |key| session_data[key] = session[key] if session[key] }
        end
        super(env, sid, session_data, options)
      end

      # The service ticket is also being stored in Memcache in the form -
      # service_ticket => session_id
      # session_id => {session_data}
      # Need to ensure that when a session is being destroyed - we also clean up the service-ticket
      # related data prior to letting the session be destroyed.
      def destroy_session(env, session_id, options)
        puts "---ActiveModelMemcacheStore--------> destroy_session: #{session_id}"
        Rails.logger.info "---ActiveModelMemcacheStore--------> destroy_session: #{session_id}"
        if @pool.exist?(session_id)
          Rails.logger.info "-----------> destroy_session 1"
          session = @pool.get(session_id)
          if session.has_key?("service_ticket") && @pool.exist?(session["service_ticket"])

            Rails.logger.info "-----------> destroy_session 2"
            begin
              Rails.logger.info "-----------> destroy_session 3 deleting"
              @pool.delete(session["service_ticket"])
            rescue Dalli::DalliError
              Rails.logger.warn("Session::DalliStore#destroy_session: #{$!.message}")
              raise if @raise_errors
            end
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

# Patch Rack 2.0 changes that broke ActionDispatch.
module ActionDispatch
  module Session
    class DalliStore < AbstractStore
      alias_method :find_session, :get_session
      alias_method :write_session, :set_session
      alias_method :delete_session, :destroy_session
    end
  end
end
