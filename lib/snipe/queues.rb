require 'beanstalk-client'
module Snipe
  module Queues
    def self.logger
      Logging::Logger[self]
    end

    def self.load_queue( cfg )
      q = nil
      begin 
        q = ::Beanstalk::Connection.new( cfg.connection, cfg.name ) 
      rescue => e
        Queues.logger.error "Failure connecting to #{cfg.connection} on tube #{cfg.name}"
        Queues.logger.error e.message
      end
      return q
    end

    def self.gnip_activity_queue
      Queues.load_queue( Configuration.for('gnip').activity_queue )
    end

    def self.gnip_parse_queue
      Queues.load_queue( Configuration.for('gnip').parse_queue )
    end
  end
end
