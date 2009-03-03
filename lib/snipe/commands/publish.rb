require 'snipe/beanstalk/observer'
require 'snipe/database'

module Snipe::Commands
  class Publish < Snipe::Command
    
    def publish_observer
      @publish_observer ||= Snipe::Beanstalk::Observer.publish_observer
    end

    def timer
      @timer ||= ::Hitimes::Timer.new
    end

    def log_stats( force = false )
      if force || (timer.count % 1000 == 0) then
        logger.info "Published #{timer.count} tweets in #{"%0.3f"% timer.sum} second at #{"%0.3f" % timer.rate} tweets / second"
      end
    end

    def shutdown
      log_stats( true )
    end

    # called by the beanstalk observer when an item is pulled off the queue
    def update( obj )
      timer.measure { 
        tweet = obj
      }
      log_stats
    end

    def run
      if publish_observer then
        publish_observer.add_observer( self )
        publish_observer.observe( options['limit'] )
      else
        logger.error "Unable to parse, not able to observe the publish queue"
      end

      shutdown
    end
  end
end
