require 'spec_helper'
require 'casclient/tickets/storage/active_model_memcache_ticket_store'
require 'dalli'

describe CASClient::Tickets::Storage::ActiveModelMemcacheTicketStore do
  it_should_behave_like "a ticket store"

  describe 'store_service_session_lookup' do
    it 'creates a session if none are found with the specified service' do
      controller = mock_controller_with_session
      controller.stub_chain(:session, :session_id).and_return("nonexistant_session")
      controller.stub_chain(:env, :[]=)

      @memcache_mock_store = {}

      service_ticket = CASClient::ServiceTicket.new("ST-id", "ActiveModelMemcacheTicketStore")
      subject.store_service_session_lookup(service_ticket, controller)
      new_session = CASClient::Tickets::Storage::MemcacheSessionStore.find_by_session_id("nonexistant_session")
      new_session.service_ticket.should eql("ST-id")
    end

    it 'updates a previously stored session' do
      controller = mock_controller_with_session
      controller.stub_chain(:session, :session_id).and_return("existing_session")
      controller.stub_chain(:env, :[]=)

      @memcache_mock_store = {"existing_session" => {"service_ticket" => "ST-id"}}

      service_ticket = CASClient::ServiceTicket.new("ST-new", "ActiveModelMemcacheTicketStore")
      subject.store_service_session_lookup(service_ticket, controller)
      subject.read_service_session_lookup(service_ticket).should eql("existing_session")
    end

    it 'uses correct controller method to access rack session environment' do
      controller = mock_controller_with_session
      controller.stub_chain(:session, :session_id).and_return('existing_session')
      controller.stub(:respond_to?) {false}
      controller.stub_chain(:request, :env, :[]=)

      @memcache_mock_store = {'existing_session' => {'service_ticket' => 'ST-id'}}

      service_ticket = CASClient::ServiceTicket.new('ST-new', 'ActiveModelMemcacheTicketStore')
      subject.store_service_session_lookup(service_ticket, controller)
      subject.read_service_session_lookup(service_ticket).should eql('existing_session')
    end
  end
end
