require 'snipe/couchdb/tweet'
module Snipe::Commands
  class Store < Snipe::Command
    def activity_queue 
      @activity_queue ||= Snipe::Queues.gnip_activity_queue
    end

    def fetcher
      unless defined? @fetcher
        @fetcher = Snipe::Twitter:Fetcher.new
      end
      return @fetcher
    end

    def run
      loop do
        job = nil
        begin
          job = activity_queue.reserve

          tweet = Marshal.restore( job.body )
          tweet['text']  = fetcher.fetch_tweet_text( tweet )
            
          job.delete
        rescue => e
          job.release unless job.nil?
          logger.error "Failure in processing a gnip activity : #{e}"
        end
      end
    end
  end
end
