require 'bundler'
Bundler.setup(:default, :development)
require 'simplecov' unless ENV['TRAVIS']
Bundler.require

require 'rubycas-client'

SPEC_TMP_DIR="spec/tmp"

Dir["./spec/support/**/*.rb"].each do |f|
  require f.gsub('.rb','') unless f.end_with? '_spec.rb'
end

require 'database_cleaner'

# TODO: see if there's a way to only do the setup/teardown for the current type of session store, instead of all 3..
RSpec.configure do |config|
  config.mock_with :rspec
  config.mock_framework = :rspec
  config.include ActionControllerHelpers

  config.before(:suite) do
    ActiveRecordHelpers.setup_active_record
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    ActiveRecordHelpers.teardown_active_record
  end

  config.before(:each) do
    DatabaseCleaner.start
    ActiveModelRedisTicketStoreHelpers.setup_redis_store
    ActiveModelMemcacheTicketStoreHelpers.setup_memcache_store
  end

  config.after(:each) do
    DatabaseCleaner.clean
    ActiveModelRedisTicketStoreHelpers.teardown_redis_store
    ActiveModelMemcacheTicketStoreHelpers.teardown_memcache_store
  end
end
