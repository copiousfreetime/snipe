require 'beanstalk-client'
module Snipe
  module Queues
    def self.logger
      Logging::Logger[self]
    end

    def self.gnip_event_queue() 
      begin
        @gnip_event_queue = ::Beanstalk::Connection.new( Configuration.for('gnip').queue.connection, 
                                                         Configuration.for('gnip').queue.name  )
      rescue => e
        cfg = Configuration.for('gnip').queue
        Queues.logger.error "Failure connecting to #{cfg.connection} on tube #{cfg.name}"
        Queues.logger.error e.message
        @gnip_event_queue = nil
      end
      return @gnip_event_queue
    end
  end
end
