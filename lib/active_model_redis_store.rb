require 'action_dispatch/middleware/session/abstract_store'
require 'action_dispatch/middleware/session/redis_store'
require 'active_support/cache/redis_store'
require 'redis-store'
require 'redis-rack'

module ActionDispatch
  module Session
    class ActiveModelRedisStore < ActionDispatch::Session::RedisStore

      # This method overrides the redis-rack gem method "delete_session"
      # https://github.com/redis-store/redis-rack/blob/master/lib/rack/session/redis.rb#L54
      #
      # The purpose is to clean up additional cas related entries in the redis cache
      # when the main rails session is destroyed.
      def delete_session(req, sid, options)
        begin
          with_lock(req, [nil, {}]) do
            last_st = if sesh = get_session_with_fallback(sid)
              sesh['cas_last_valid_ticket']
            end

            with do |c|
              Rails.logger.info "deleting service-ticket with key #{"#{options[:namespace]}:#{last_st}"}"
              [last_st, sid].each do |t|
                c.del([options[:namespace], t].compact.join(':'))
              end
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
