require 'beanstalk-client'
require 'observer'

require 'snipe/beanstalk/queue'

module Snipe
  module Beanstalk
    class Observer < Queue
      include Observable

      def self.split_observer
        @split ||= Observer.new( Beanstalk::Queue.split_queue )
      end
      
      def self.scrape_observer
        @scrape ||= Observer.new( Beanstalk::Queue.scrape_queue )
      end

      def self.publish_observer
        @publish ||= Observer.new( Beanstalk::Queue.publish_queue )
      end

      # the maximum number of errors to hit before stopping the connection to
      # the beanstalk queue
      def self.default_error_limit
        20
      end

      attr_reader :error_limit
      attr_reader :error_count

      attr_reader :job_limit
      attr_reader :jobs_processed

      def initialize( cfg_or_queue )
        unless cfg_or_queue.instance_of?( Beanstalk::Queue ) then
          cfg_or_queue = Beanstalk::Queue.new( cfg_or_queue )
        end
        @connection     = cfg_or_queue.connection
        @configuration  = cfg_or_queue.configuration
        @error_limit    = configuration.error_limit || Queue.default_error_limit
        @error_count    = 0
        @jobs_processed = 0
        @job_limit      = nil
        @stopped        = false
      end

      def limits_reached?
        return true if error_count >= error_limit
        return true if job_limit && (jobs_processed >= job_limit)
        return @stopped
      end

      def stop
        @stopped = true
      end

      # this loops forever and does not return until the error count is too much
      # or the number of iterations has been reached
      def observe( limit = nil )
        logger.info "Starting observation loop on #{name}"
        if limit then 
          @job_limit = limit
          logger.info "  limiting to processing #{job_limit} jobs"
        end
        loop do
          break if limits_reached?
          job = nil
          begin
            job = self.reserve
            self.changed
            self.notify_observers( job.body )
            job.delete
            @jobs_processed += 1
          rescue => e
            job.release unless job.nil?
            logger.error "Failure in procssing job : #{e}"
            @error_count += 1
          end
        end

        logger.info "Stopping observation loop on #{name} : errors #{error_count} : jobs_processed #{jobs_processed}"
        self.close

        if error_count >= error_limit then
          msg = "Too many Errors (count : #{error_count}) observing #{name}"
          logger.fatal msg
          raise Snipe::Error, msg
        elsif job_limit && (jobs_processed >= job_limit ) then
          logger.info "  job limit of #{job_limit} reached"
        elsif 
          logger.info "  told to stop"
        end
      end
    end
  end
end
