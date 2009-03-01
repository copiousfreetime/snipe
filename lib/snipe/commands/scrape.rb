require 'snipe/couchdb/tweet_store'
require 'snipe/beanstalk/observer'
require 'snipe/tweet_fetcher'

module Snipe::Commands
  class Scrape < Snipe::Command
    def scrape_observer
      @scrape_observer ||= Snipe::Beanstalk::Observer.scrape_observer
    end
    
    def store_queue
      @store_queue ||= Snipe::Beanstalk::Queue.store_queue
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
        logger.info "Fetched #{timer.count} tweets in #{"%0.3f"% timer.sum} second at #{"%0.3f" % timer.rate} tweets / second"
      end
    end

    def shutdown
      fetcher.log_stats( true )
      log_stats( true )
    end

    # callec by the beanstalk observer when an item is pulled off the queue
    def update( obj )
      tweet = Marshal.restore( obj )
      timer.measure { 
        catch(:skip_fetch) do
          tweet.text = fetcher.fetch_text( tweet )
          tweet.scrape_at = Time.now_as_mjd_stamp
          store_queue.put( Marshal.dump( tweet ) )
        end
      }
      log_stats
    end

    def run
      if scrape_observer then
        scrape_observer.add_observer( self )
        scrape_observer.observe( options['limit'] )
      else
        logger.error "Unable to parse, not able to observe the scrape ueue"
      end

      shutdown
    end
  end
end
