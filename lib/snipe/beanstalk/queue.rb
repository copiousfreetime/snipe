require 'beanstalk-client'

module Snipe
  module Beanstalk
    # very thin wrapper around a beanstalk queue
    class Queue

      # handles for the standard queues, only set them if a connection is
      # successful
      def self.activity_queue
        @activity ||= Queue.load_queue( Configuration.for('gnip').activity_queue ) 
      end

      def self.parse_queue
        @parse ||= Queue.load_queue( Configuration.for('gnip').parse_queue )
      end

      def self.load_queue( cfg )
        q = Queue.new( cfg )
        return q if q.connected?
        return nil
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

      def logger
        Logging::Logger[self]
      end

      def reserve
        connection.reserve
      end

      def connected?
        !@connection.nil?
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

