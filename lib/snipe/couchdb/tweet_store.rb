require 'couchrest'
module Snipe
  module CouchDB
    class TweetStore < ::CouchRest::Database

      def self.server
        @server ||= ::CouchRest::Server.new( configuration.server )
      end

      def self.configuration
        @configuration ||= Configuration.for('couchdb').tweet_db
      end

      def self.db_name 
        @db_name ||= configuration.db_name
      end

      def initialize( db_name = nil )
        db_name ||= TweetStore.db_name
        super( TweetStore.server, db_name )
        self.bulk_save_cache_limit = TweetStore.configuration.bulk_insert

        server.create_db( self.name ) rescue nil # create it if it doesn't exist
      end

      def logger
        Logging::Logger[self]
      end
      
      def timer
        @timer ||= ::Hitimes::Timer.new
      end

      def log_stats( force = false )
        if force || (timer.count % 100 == 0) then
          logger.info "Stored #{timer.count} tweets in #{"%0.3f"% timer.sum} second at #{"%0.3f" % timer.rate} tweets / second"
        end
      end

      alias :orig_save :save
      def save( doc )
        timer.measure {
          self.orig_save( doc, bulk? )
        }
        log_stats
      end

      def bulk?
        @bulk ||= ( TweetStore.configuration.bulk_insert ? true : false )
      end

      def flush
        timer.measure {
          self.bulk_save
        }
        log_stats( true )
      end
    end
  end
end
