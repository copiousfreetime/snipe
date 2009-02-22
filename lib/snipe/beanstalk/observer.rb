require 'beanstalk-client'
require 'observer'

require 'snipe/beanstalk/queue'

module Snipe
  module Beanstalk
    class Observer < Queue
      include Observable

      # handles for the standard observers
      def self.activity_observer
        @activity ||= Observer.new( Beanstalk::Queue.activity_queue )
      end

      def self.parse_observer
        @parse ||= Observer.new( Beanstalk::Queue.parse_queue )
      end

      # the maximum number of errors to hit before stopping the connection to
      # the beanstalk queue
      def self.default_error_limit
        20
      end

      attr_reader :error_limit
      attr_reader :error_count

      def initialize( cfg_or_queue )
        unless cfg_or_queue.instance_of?( Beanstalk::Queue ) then
          cfg_or_queue = Beanstalk::Queue.new( cfg_or_queue )
        end
        @connection    = cfg_or_queue.connection
        @configuration = cfg_or_queue.configuration
        @error_limit   = configuration.error_limit || Queue.default_error_limit
        @error_count   = 0
      end

      # this loops forever and does not return until the error count is too much
      def observe
        logger.info "Starting observation loop on #{name}"
        while error_count < error_limit do
          job = nil
          begin
            job = self.reserve
            self.changed
            self.notify_observers( job.body )
            job.delete
          rescue => e
            job.release unless job.nil?
            logger.error "Failure in procssing job : #{e}"
            @error_count += 1
          end
        end

        msg = "Too many Errors (count : #{error_count}) observing #{cfg.connection}/#{cfg.name}"
        logger.fatal msg
        raise Snipe::Error, msg
      end
    end
  end
end
