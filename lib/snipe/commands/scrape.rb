require 'snipe/couchdb/tweet_store'
require 'snipe/beanstalk/observer'
require 'snipe/tweet_fetcher'

module Snipe::Commands
  class Scrape < Snipe::Command
    def split_observer
      @split_observer ||= Snipe::Beanstalk::Observer.split_observer
    end
    
    def publish_queue
      @publish_queue ||= Snipe::Beanstalk::Queue.publish_queue
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

    def shutdown
      fetcher.log_stats( true )
      tweet_store.flush
      log_stats( true )
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
      if split_observer then
        split_observer.add_observer( self )
        split_observer.observe( options['limit'] )
      else
        logger.error "Unable to parse, not able to observe the activity queue"
      end

      shutdown
    end
  end
end
