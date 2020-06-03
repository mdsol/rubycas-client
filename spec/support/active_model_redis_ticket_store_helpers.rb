module ActiveModelRedisTicketStoreHelpers
  class << self
    def setup_redis_store
      teardown_redis_store

      Redis.any_instance.stub(:set) do |key, value|
        @redis_mock_store[key] = value
      end

      Redis.any_instance.stub(:get) do |key|
        @redis_mock_store[key]
      end

      Redis.any_instance.stub(:delete) do |key|
        @redis_mock_store.delete(key)
        @redis_mock_store
      end
    end

    def teardown_redis_store
      @redis_mock_store = {}
    end

    def set_store_value(hash)
      @redis_mock_store = hash
    end
  end
end
