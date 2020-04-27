require 'uri'
require 'cgi'
require 'logger'
require 'net/https'
require 'rexml/document'
require 'casclient/dice_bag/cas_template'
require 'active_model_memcache_store'

begin
  require 'active_support'
rescue LoadError
  require 'rubygems'
  require 'active_support'
end

$: << File.expand_path(File.dirname(__FILE__))

module CASClient
  class CASException < Exception
  end

  # Customized logger for the client.
  # This is useful if you're trying to do logging in Rails, since Rails'
  # clean_logger.rb pretty much completely breaks the base Logger class.
  class Logger < ::Logger
    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      @default_formatter = Formatter.new
      super
    end
  
    def format_message(severity, datetime, progrname, msg)
      (@formatter || @default_formatter).call(severity, datetime, progname, msg)
    end
    
    def break
      self << $/
    end
    
    class Formatter < ::Logger::Formatter
      Format = "[%s#%d] %5s -- %s: %s\n"
      
      def call(severity, time, progname, msg)
        Format % [format_datetime(time), $$, severity, progname, msg2str(msg)]
      end
    end
  end

  # Wraps a real Logger. If no real Logger is set, then this wrapper
  # will quietly swallow any logging calls.
  class LoggerWrapper
    def initialize(real_logger=nil)
      set_logger(real_logger)
    end
    # Assign the 'real' Logger instance that this dummy instance wraps around.
    def set_real_logger(real_logger)
      @real_logger = real_logger
    end
    # Log using the appropriate method if we have a logger
    # if we dont' have a logger, gracefully ignore.
    def method_missing(name, *args)
      if !@real_logger.nil? && @real_logger.respond_to?(name)
        @real_logger.send(name, *args)
      end
    end
  end
end

require 'casclient/tickets'
require 'casclient/responses'
require 'casclient/client'
require 'casclient/tickets/storage'

# Arel errors in case >= ruby 2.4.0
# need to create aliases as given in the file

require 'arel'
if Arel::VERSION.to_f < 6.0
  require 'casclient/arel_alias'
end

autoload :ACTIVE_RECORD_TICKET_STORE, 'casclient/tickets/storage/active_record_ticket_store'
autoload :ACTIVE_MODEL_MEMCACHE_TICKET_STORE, 'casclient/tickets/storage/active_model_memcache_ticket_store'
autoload :ACTIVE_MODEL_REDIS_TICKET_STORE, 'casclient/tickets/storage/active_model_redis_ticket_store'
if defined?(Rails)
  require 'casclient/frameworks/rails/filter'
  require 'casclient/frameworks/rails/cas_proxy_callback_controller'
end

# Detect legacy configuration and show appropriate error message
module CAS
  module Filter
    class << self
    def method_missing(method, *args)
      $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      $stderr.puts
      $stderr.puts "WARNING: Your RubyCAS-Client configuration is no longer valid!!"
      $stderr.puts
      $stderr.puts "For information on the new configuration format please see: "
      $stderr.puts
      $stderr.puts "   http://rubycas-client.googlecode.com/svn/trunk/rubycas-client/README.txt"
      $stderr.puts
      $stderr.puts "After upgrading your configuration you should also clear your application's session store."
      $stderr.puts
      $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    end
    end
  end
end
