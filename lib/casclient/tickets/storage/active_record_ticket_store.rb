module CASClient
  module Tickets
    module Storage

      # A Ticket Store that keeps it's ticket in database tables using ActiveRecord.
      #
      # Services Tickets are stored in an extra column add to the ActiveRecord sessions table.
      # Proxy Granting Tickets and their IOUs are stored in the cas_pgtious table.
      #
      # This ticket store takes the following config parameters
      # :pgtious_table_name - the name of the table
      class ActiveRecordTicketStore < AbstractTicketStore

        def initialize(config={})
          config ||= {}
          if config[:pgtious_table_name]
            CasPgtiou.set_table_name = config[:pgtious_table_name]
          end
        end

        def store_service_session_lookup(st, controller)
          raise CASException, 'No service_ticket specified.' unless st
          raise CASException, 'No controller specified.' unless controller

          st = st.ticket if st.kind_of? ServiceTicket
          session_id = session_id_from_controller(controller)

          # Create a session in the DB if it hasn't already been created.
          unless ActiveRecord::SessionStore::Session.find_by_session_id(session_id)
            log.info("RubyCAS Client did not find #{session_id} in the Session Store. Creating it now!")
            # We need to use .save instead of .create or the service_ticket won't be stored
            new_session = ActiveRecord::SessionStore::Session.new
            new_session.service_ticket = st
            new_session.session_id = session_id
            new_session.data = {}
            if new_session.save
              # Set the rack session record variable so the service doesn't create a duplicate session and instead updates
              # the data attribute appropriately.
              controller.request.env['rack.session.record'] = new_session # For rails 5.1+, ActionController#env is deprecated
            else
              raise CASException, "Unable to store session #{session_id} for service ticket #{st} in the database."
            end
          else
            update_all_sessions(session_id, st)
          end
        end

        def read_service_session_lookup(st)
          raise CASException, "No service_ticket specified." unless st
          st = st.ticket if st.kind_of? ServiceTicket
          session = ActiveRecord::SessionStore::Session.find_by_service_ticket(st)
          session ? session.session_id : nil
        end

        def cleanup_service_session_lookup(st)
          #no cleanup needed for this ticket store
          #we still raise the exception for API compliance
          raise CASException, "No service_ticket specified." unless st
        end

        def save_pgt_iou(pgt_iou, pgt)
          raise CASClient::CASException.new("Invalid pgt_iou") if pgt_iou.nil?
          raise CASClient::CASException.new("Invalid pgt") if pgt.nil?
          pgtiou = CasPgtiou.create(:pgt_iou => pgt_iou, :pgt_id => pgt)
        end

        def retrieve_pgt(pgt_iou)
          raise CASException, "No pgt_iou specified. Cannot retrieve the pgt." unless pgt_iou

          pgtiou = CasPgtiou.find_by_pgt_iou(pgt_iou)

          raise CASException, "Invalid pgt_iou specified. Perhaps this pgt has already been retrieved?" unless pgtiou
          pgt = pgtiou.pgt_id

          pgtiou.destroy

          pgt

        end

        private
        def update_all_sessions(session_id, service_ticket)
          if ActiveRecord::VERSION::MAJOR.to_i >= 4
            ActiveRecord::SessionStore::Session.where(session_id: session_id).
              update_all(service_ticket: service_ticket)
          else
            ActiveRecord::SessionStore::Session.update_all(
                %(service_ticket='%s') % service_ticket,
                ["session_id=?", session_id])
          end
        end
      end

      ::ACTIVE_RECORD_TICKET_STORE = ActiveRecordTicketStore

      class CasPgtiou < ActiveRecord::Base
        #t.string :pgt_iou, :null => false
        #t.string :pgt_id, :null => false
        #t.timestamps
      end
    end
  end
end
