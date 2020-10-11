require 'spec_helper'
require 'active_model_memcache_store'
require 'dalli'

describe ActionDispatch::Session::ActiveModelMemcacheStore do

  describe 'session_destroy' do

    pool = ActionDispatch::Session::ActiveModelMemcacheStore.new nil, {
        :cache => ActiveSupport::Cache::DalliStore.new("localhost:70"),
        :key => "_session_id",
        :secret => "SESSION_SECRET_KEY",
        :session_id => '12345',
        :raise_errors => true,
        :secure => false }

    subject { pool }

    it 'logs warning if pool dosnt contain session' do
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:exist?).and_return(true)
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      expect(logger).to receive(:warn).with("Session::ActiveModelMemcacheStore#destroy_session: the retrieved pool session for session_id 12345 is nil")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'logs error if session is in pool yet cannot be retrieved' do
      logger = double('logger')
      allow(CASClient::LoggerWrapper).to receive(:new).and_return(logger)
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:exist?).and_return(true, false)
      expect(logger).to receive(:warn).with("Session::ActiveModelMemcacheStore#destroy_session: Session  12345 has_key?: true, @pool.exist?: false")
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'deletes the session if it exists' do
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      expect { subject.destroy_session '','12345', {} }.not_to raise_error
    end

    it 'logs Dalli error if exception is raised' do
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:get).and_return( { "service_ticket" => "12345" } )
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:exist?).and_return(true, true)
      allow(subject).to receive(:get).and_return({ service_ticket: '12345' })
      allow_any_instance_of(ActiveSupport::Cache::DalliStore).to receive(:delete).and_raise( Dalli::DalliError)
      expect { subject.destroy_session '','12345', {} }.to raise_error("Dalli::DalliError")
    end
  end
end
