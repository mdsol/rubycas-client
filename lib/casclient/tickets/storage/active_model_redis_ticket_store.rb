require 'casclient/frameworks/rails/filter'

module CASClient
  module Tickets
    module Storage

      # TODO: this is based on ActiveModelRedisTicketStore. there could be issues but most of the logic seems independent of memcached vs redis.
      class ActiveModelRedisTicketStore < AbstractTicketStore
        def initialize(config={})
          log.info("ActiveModelRedisTicketStore adapted for redis")
          config ||= {}
          RedisSessionStore.client(config) if config
        end

        def store_service_session_lookup(st, controller)
          raise CASException, 'No service_ticket specified.' unless st
          raise CASException, 'No controller specified.' unless controller
          st = st.ticket if st.kind_of? ServiceTicket
          session_id = session_id_from_controller(controller)
          # Create a session in the DB if it hasn't already been created.

          unless RedisSessionStore.find_by_session_id(session_id)
            log.info("RubyCAS Client did not find #{session_id} in the Session Store. Creating it now!")
            # We need to use .save instead of .create or the service_ticket won't be stored
            new_session = RedisSessionStore.new
            new_session.service_ticket = st
            new_session.session_id = session_id

            if new_session.save
              # Set the rack session record variable so the service doesn't create a duplicate session and instead updates
              # the data attribute appropriately.
              controller.request.env['rack.session.record'] = new_session
            else
              raise CASException, "Unable to store session #{session_id} for service ticket #{st} in the database."
            end
          else
            update_all_sessions(session_id, st)
          end
        end

        def get_session_for_service_ticket(st)
          session_id = read_service_session_lookup(st)
          session = session_id ? RedisSessionStore.find_by_session_id(session_id) : nil
          [session_id, session]
        end

        def read_service_session_lookup(st)
          raise CASException, 'No service_ticket specified.' unless st
          st = st.ticket if st.kind_of? ServiceTicket
          RedisSessionStore.find_by_service_ticket(st)
        end

        def cleanup_service_session_lookup(st)
          #no cleanup needed for this ticket store
          #we still raise the exception for API compliance
          raise CASException, 'No service_ticket specified.' unless st
        end

        def save_pgt_iou(pgt_iou, pgt)
          raise CASClient::CASException.new('Invalid pgt_iou') unless pgt_iou
          raise CASClient::CASException.new('Invalid pgt') unless pgt
          pgtiou = Pgtiou.create(pgt_iou: pgt_iou, pgt_id: pgt)
        end

        def retrieve_pgt(pgt_iou)
          raise CASException, 'No pgt_iou specified. Cannot retrieve the pgt.' unless pgt_iou
          pgtiou = Pgtiou.find_by_pgt_iou(pgt_iou)
          raise CASException, 'Invalid pgt_iou specified. Perhaps this pgt has already been retrieved?' unless pgtiou

          pgt = pgtiou.pgt_id
          pgtiou.destroy
          pgt
        end

        private
        def update_all_sessions(session_id, service_ticket)
          session = RedisSessionStore.find_by_session_id(session_id)
          session["session_id"] = session_id
          session["service_ticket"] = service_ticket
          session.save
        end

      end

      ::ACTIVE_MODEL_REDIS_TICKET_STORE = ActiveModelRedisTicketStore

      class RedisSessionStore
        include ActiveModel
        attr_accessor :session_id, :service_ticket, :data

        def initialize(options={})
          options.each do |key, val|
            self.instance_variable_set("@#{key}", val)
          end
          self
        end

        def [](key)
          self.instance_variable_get("@#{key}")
        end

        def []=(key, value)
          self.instance_variable_set("@#{key}", value)
        end

        def self.client(config)
          puts "rubycas-client===========> #{config.inspect}"
          log.info("rubycas-client===========> #{config.inspect}")

          memcache_url = config && config[:dalli_settings] && "#{config[:dalli_settings]['host']}:#{config[:dalli_settings]['port']}" || 'localhost:6379'
          options = config[:dalli_settings].clone if config.has_key?(:dalli_settings)
          options.delete("host") if options && options.has_key?("host")
          options.delete("port") if options && options.has_key?("port")
          @@options = options || {}

          puts "rubycas-client======@@redis_client=====> #{@@redis_client.inspect}"
          puts "rubycas-client======url=====> #{"rediss://#{config[:dalli_settings]['host']}:6379/0"}"
          log.info "rubycas-client======@@redis_client=====> #{@@redis_client.inspect}"
          log.info "rubycas-client======url=====> #{"rediss://#{config[:dalli_settings]['host']}:6379/0"}"

          @@redis_client ||= Redis.new(url: "rediss://#{config[:dalli_settings]['host']}:6379/0")
        end

        def self.find_by_session_id(session_id)
          session_id = "#{namespaced_key(session_id)}"
          session = @@redis_client.get(session_id)
          # A session is generated immediately without actually logging in, the below line
          # validates that we have a service_ticket so that we can store additional information
          if session
            RedisSessionStore.new(session)
          else
            return false
          end
        end

        def self.find_by_service_ticket(service_ticket)
          session_id = @@redis_client.get("#{namespaced_key(service_ticket)}")
          session = RedisSessionStore.find_by_session_id(session_id) if session_id
          session.session_id if session
        end

        def session_data
          data = {}
          self.instance_variables.each{|key| data[key.to_s.sub(/\A@/, '')] = self[key.to_s.sub(/\A@/, '')]}
          data
        end

        # As Memcache is a key value store we are storing the session in the form of
        # session_id => {session_data}
        #
        # We do also need to be able to retrieve the session using just the service_ticket, and as
        # this is a key value store - we need to store the service_ticket as a key - pointing to
        # the session_id which will give us the session data
        # service_ticket => session_id
        # session_id => {session_data}
        def save
          @@redis_client.set("#{namespaced_key(self.service_ticket)}", self.session_id)
          @@redis_client.set("#{namespaced_key(self.session_id)}", self.session_data)
        end

        def destroy
          @@redis_client.delete("#{namespaced_key(self.service_ticket)}")
          @@redis_client.delete("#{namespaced_key(self.session_id)}")
        end

        alias_method :save!, :save

        # Need to access the namespaced_key method through both class methods as
        # well as instance methods.
        # Hence having the same name methods for both class and instance.
        def self.namespaced_key(key)
          if @@options['namespace']
            "#{@@options['namespace']}:#{key}"
          else
            key.to_s
          end
        end

        def namespaced_key(key)
          self.class.namespaced_key(key)
        end
      end

      class Pgtiou
        include ActiveModel
        attr_accessor :pgt_iou, :pgt_id

        puts "rubycas-client===Pgtiou========> #{"rediss://#{config[:dalli_settings]['host']}:6379/0"}"
        log.info("rubycas-client===Pgtiou========> #{"rediss://#{config[:dalli_settings]['host']}:6379/0"}")
        @@redis_client = Redis.new(url: "rediss://#{config[:dalli_settings]['host']}:6379/0")

        def initialize(options={})
          @pgt_iou = options[:pgt_iou]
          @pgt_id = options[:pgt_id]
        end

        def self.find_by_pgt_iou(pgt_iou)
          pgtiou = @@redis_client.get(pgt_iou)
          Pgtiou.new(pgtiou) if pgtiou
        end

        def self.create(options)
          pgtiou = Pgtiou.new(options)
          @@redis_client.set(pgtiou.pgt_iou, pgtiou.session_data)
        end

        def session_data
          {pgt_iou: self.pgt_iou, pgt_id: self.pgt_id}
        end

        def destroy
          @@redis_client.delete(self.pgt_iou)
        end
      end
    end
  end
end