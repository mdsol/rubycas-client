require 'action_dispatch/middleware/session/abstract_store'
require 'action_dispatch/middleware/session/redis_store'
require 'active_support/cache/redis_store'
require 'redis-store'
require 'redis-rack'

module ActionDispatch
  module Session
    class ActiveModelRedisStore < ActionDispatch::Session::RedisStore
      def delete_session(req, sid, options)
        Rails.logger.info "==================> ActiveModelRedisStore <====delete_session================="
        begin
          with_lock(req, [nil, {}]) do
            if sesh = get_session_with_fallback(sid)
              last_st = sesh['cas_last_valid_ticket']
            end
            with do |c|
              c.del("checkmate:#{last_st}")
              c.del("checkmate:#{sid}")
              Rails.logger.info "==================> ActiveModelRedisStore <====deleted cas stuff================="
            end
          end
        rescue => e
          Rails.logger.info "Error cleaning up cas cache data: #{e}"
        end

        super
      end

    end
  end
end
