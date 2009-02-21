require 'nokogiri'
require 'snipe/gnip/document'
require 'zlib'
module Snipe
  module Gnip
    class Parser < ::Nokogiri::XML::SAX::Parser
      attr_accessor :beanstalk_server

      def self.parse_gnip_notification( fname )
        p = self.new
        p.parse_gnip_notification( fname )
        return p
      end

      def self.default_opts
        { :doc => Gnip::Document.new,
          :beanstalk_server => :default }
      end
      
      def logger
        Logging::Logger[self]
      end

      def initialize( opts = {} )
        opts = Parser.default_opts.merge( opts )
        doc = opts.delete( :doc )

        super( doc )
        case bean_opt = opts[:beanstalk_server]
        when nil
          @beanstalk_server = nil
        when :default
          @beanstalk_server = Snipe::Queues.gnip_event_queue rescue nil
        else
          if bean_opt.respond_to?( :put ) then
            @beanstalk_server = bean_opt
          else
            logger.error "the value given for :beanstalkd_server does not respond to put() => #{bean_opt.inspect}" 
            @beanstalk_server = nil
          end
        end
        logger.info "Connected to beanstalkd server #{beanstalk_server.addr}/#{beanstalk_server.list_tube_used}" if beanstalk_server

        self.document.add_observer( self )
      end

      def put_timer
        @put_timer ||= ::Hitimes::Timer.new
      end

      # only registered as an observer if there is a beanstalk server
      def update( *args )
        event = args.first
        put_timer.measure {
          beanstalk_server.put( Marshal.dump( event ) ) if beanstalk_server
        }

      end

      def parse_gnip_notification( fname )
        logger.info "Start parsing #{fname}"
        duration = ::Hitimes::Interval.measure {
          io = Zlib::GzipReader.open( fname )
          parse_io( io )
          io.close
        }
        mps = put_timer.count / duration

        logger.info "  --> Summary <--"
        logger.info "    beanstalk put : #{put_timer.count} at #{"%0.3f" % put_timer.rate} mps for a total of #{"%0.3f" % put_timer.sum} seconds"
        logger.info "    the rest      : #{put_timer.count} at #{"%0.3f" % mps} mps for a total of #{"%0.3f" % duration} seconds"
        logger.info "Done parsing #{fname}"
      end
    end
  end
end
