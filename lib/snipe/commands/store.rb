require 'snipe/couchdb/tweet'
require 'snipe/beanstalk/observer'
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

    # callec by the beanstalk observer when an item is pulled off the queue
    def update( obj )
      tweet = Marshal.restore( obj )
      tweet.text = fetcher.fetch_text( tweet )
      tweet_store.save( tweet )
    end

    def run
      if activity_queue_observer then
        activity_queue_observer.add_observer( self )
        activity_queue_observer.observe
      else
        logger.error "Unable to parse, not able to observe the activity queue"
      end
    end
  end
end
