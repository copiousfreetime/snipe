require 'snipe/beanstalk/observer'
require 'snipe/database'

module Snipe::Commands
  class Store < Snipe::Command
    def store_observer
      @store_observer ||= Snipe::Beanstalk::Observer.store_observer
    end
    
    def publish_queue
      @publish_queue ||= Snipe::Beanstalk::Queue.publish_queue
    end

    def timer
      @timer ||= ::Hitimes::Timer.new
    end

    def database
      @database ||= ::Snipe::Database.tweet_db
    end

    def log_stats( force = false )
      if force || (timer.count % 1000 == 0) then
        logger.info "Stored #{timer.count} tweets in #{"%0.3f"% timer.sum} second at #{"%0.3f" % timer.rate} tweets / second"
      end
    end

    def shutdown
      store_observer.stop if store_observer 
      log_stats( true )
    end

    # called by the beanstalk observer when an item is pulled off the queue
    def update( obj )
      tweet = Marshal.restore( obj )
      timer.measure { 
        tweet.store_at = Time.now_as_mjd_stamp
        database[tweet.key] = tweet.to_hash
        publish_queue.put( tweet.key )
      }
      log_stats
    end

    def run
      if store_observer then
        store_observer.add_observer( self )
        store_observer.observe( options['limit'] )
      else
        logger.error "Unable to parse, not able to observe the store queue"
      end

      shutdown
    end
  end
end
