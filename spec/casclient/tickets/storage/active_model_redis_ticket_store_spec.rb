require 'spec_helper'
require 'casclient/tickets/storage/active_model_redis_ticket_store'
require 'casclient/tickets/storage/active_model_memcache_ticket_store'
require 'casclient/tickets/storage/active_record_ticket_store' # TODO: remove this. only needed to make before :suite pass in spec_helper. (and maybe clean up spec_helper)

describe CASClient::Tickets::Storage::ActiveModelRedisTicketStore do
  it_should_behave_like "a ticket store"

  describe 'store_service_session_lookup' do
    it 'creates a session if none are found with the specified service' do
      controller = mock_controller_with_session
      controller.stub_chain(:session, :session_id).and_return('nonexistent_session')
      controller.stub_chain(:request, :env, :[]=)
      service_ticket = CASClient::ServiceTicket.new("ST-id", "1234567890")
      subject.store_service_session_lookup(service_ticket, controller)
      new_session = CASClient::Tickets::Storage::RedisSessionStore.find_by_session_id('nonexistent_session')
      new_session.service_ticket.should eql("ST-id")
    end

    it 'updates a previously stored session' do
      controller = mock_controller_with_session
      controller.stub_chain(:session, :session_id).and_return("existing_session")
      controller.stub_chain(:request, :env, :[]=)

      ActiveModelRedisTicketStoreHelpers.set_store_value({'existing_session' => {'service_ticket' => 'ST-id'}})

      service_ticket = CASClient::ServiceTicket.new('ST-new', '1234567890')
      subject.store_service_session_lookup(service_ticket, controller)
      subject.read_service_session_lookup(service_ticket).should eql('existing_session')
    end
  end
end
