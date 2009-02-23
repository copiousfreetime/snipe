require 'snipe/couchdb/tweet_store'
require 'snipe/beanstalk/observer'
require 'snipe/tweet_fetcher'

module Snipe::Commands
  class Store < Snipe::Command
    def activity_queue_observer
      @activity_queue_observer ||= Snipe::Beanstalk::Observer.activity_observer
    end

    def tweet_store
      @tweet_store ||= Snipe::CouchDB::TweetStore.new
    end

    def fetcher
      unless defined? @fetcher
        @fetcher = Snipe::TweetFetcher.new
      end
      return @fetcher
    end

    def timer
      @timer ||= ::Hitimes::Timer.new
    end

    def log_stats( force = false )
      if force || (timer.count % 100 == 0) then
        logger.info "Fetched and Stored #{timer.count} tweets in #{"%0.3f"% timer.sum} second at #{"%0.3f" % timer.rate} tweets / second"
      end
    end

    # callec by the beanstalk observer when an item is pulled off the queue
    def update( obj )
      tweet = Marshal.restore( obj )
      timer.measure { 
        catch(:skip_fetch) do
          tweet.text = fetcher.fetch_text( tweet )
          tweet_store.save( tweet )
        end
      }
      log_stats
    end

    def run
      if activity_queue_observer then
        activity_queue_observer.add_observer( self )
        activity_queue_observer.observe( options['limit'] )
      else
        logger.error "Unable to parse, not able to observe the activity queue"
      end

      fetcher.log_stats( true )
      tweet_store.flush
      log_stats( true )
    end
  end
end
