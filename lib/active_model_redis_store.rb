require 'action_dispatch/middleware/session/abstract_store'
require 'action_dispatch/middleware/session/redis_store'
require 'active_support/cache/redis_store'
require 'redis-store'
require 'redis-rack'

module ActionDispatch
  module Session

    class ActiveModelRedisStore < ActionDispatch::Session::RedisStore
    # class ActiveModelRedisStore < ActionDispatch::Session::AbstractStore
      def write_session(env, sid, session_data, options = nil)
        Rails.logger.info("------set_session-------->  #{env.inspect[0..1000]}, sid: #{sid}")
        Rails.logger.info("------set_session---test get1----->  #{@pool rescue 'no pool'}")
        Rails.logger.info("------set_session---test get2----->  #{@pool.get(sid) rescue 'nope'}")
        if session = with { |c| c.get(sid) }
          # Copy session_id and service_ticket into the session_data
          %w(session_id service_ticket).each { |key| session_data[key] = session[key] if session[key] }
          session['TESTKEY'] = '12345'
          Rails.logger.info("------session_data-------->  #{session_data}")
        else
          Rails.logger.info("------session_data-------->  could not find session")
        end
        # write_session(env, sid, session_data, options)
        super(env, sid, session_data, options)
      end
    #
    #   # The service ticket is also being stored in Memcache in the form -
    #   # service_ticket => session_id
    #   # session_id => {session_data}
    #   # Need to ensure that when a session is being destroyed - we also clean up the service-ticket
    #   # related data prior to letting the session be destroyed.
    #   def destroy_session(env, session_id, options)
    #     Rails.logger.info("------destroy_session-------->  #{env.inspect[0..1000]}, session_id: #{session_id}, #{options.inspect}")
    #     if session = with { |client| client.get(session_id) }
    #       if session.has_key?('service_ticket')
    #         Rails.logger.info("------session['service_ticket']----->  #{session['service_ticket']}")
    #         begin
    #           with { |client| client.del(session['service_ticket']) }
    #         rescue => e
    #           Rails.logger.warn("error in destroy_session: #{$!.message}")
    #           raise if @raise_errors
    #         end
    #       end
    #     end
    #     delete_session(env, session_id, options)
    #   end
    #
    #   def find_session(env, sid)
    #     session = with { |client| client.get(sid) }
    #     Rails.logger.info("------find_session-------->  #{env.inspect[0..1000]}, sid: #{sid}, session: #{session.inspect[0..1000]}")
    #     [sid, session]
    #   end

      # TODO: apparently not needed for redis
      # Patch Rack 2.0 changes that broke ActionDispatch.
      # alias_method :find_session, :get_session
      # alias_method :write_session, :set_session
      # alias_method :delete_session, :destroy_session

    end
  end
end

# TODO: apparently not needed for redis
# module ActiveSupport
#   module Cache
#     class RedisCacheStore
#       alias_method :get, :read
#       alias_method :set, :write
#     end
#   end
# end
