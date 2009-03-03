require 'beanstalk-client'
require 'snipe/configuration'

module Snipe
  module Beanstalk
    # very thin wrapper around a beanstalk queue
    class Queue

      # handles for the standard queues, only set them if a connection is
      # successful
      def self.split_queue
        @split ||= Queue.load_queue( Configuration.for('queues').split )
      end

      def self.scrape_queue
        @scrape ||= Queue.load_queue( Configuration.for('queues').scrape ) 
      end
      
      def self.store_queue
        @store ||= Queue.load_queue( Configuration.for('queues').store ) 
      end

      def self.publish_queue
        @publish ||= Queue.load_queue( Configuration.for('queues').publish ) 
      end

      def self.load_queue( cfg )
        q = Queue.new( cfg )
        return q if q.connected?
        return nil
      end

      def self.list
        [ split_queue, scrape_queue, store_queue, publish_queue ]
      end

      attr_reader :connection
      attr_reader :configuration

      def initialize( cfg )
        @configuration = cfg
        connect
      end

      def connect
        @connection = ::Beanstalk::Connection.new( configuration.connection, configuration.name ) 
      rescue => e
        logger.error "Failure connecting to #{self.name}"
        raise e
      end

      def close
        @connection.close
        @connection = nil
      end

      def logger
        Logging::Logger[self]
      end

      def reserve
        connection.reserve
      end

      def connected?
        !@connection.nil?
      end

      def stats
        @connection.stats_tube( configuration.name )
      end

      def name
        "#{configuration.connection}/#{configuration.name}"
      end

      def put( obj )
        connection.put( obj )
      end
    end
  end
end

