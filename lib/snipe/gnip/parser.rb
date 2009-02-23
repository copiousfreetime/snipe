require 'nokogiri'
require 'snipe/gnip/document'
require 'zlib'
require 'snipe/beanstalk/queue'
module Snipe
  module Gnip
    class Parser < ::Nokogiri::XML::SAX::Parser
      attr_accessor :notify

      def self.parse_gnip_notification( fname )
        p = self.new
        p.parse_gnip_notification( fname )
        return p
      end

      def self.default_opts
        { :doc => Gnip::Document.new,
          :notify => :default }
      end
      
      def logger
        Logging::Logger[self]
      end

      def initialize( opts = {} )
        opts = Parser.default_opts.merge( opts )
        doc = opts.delete( :doc )

        super( doc )
        case bean_opt = opts[:notify]
        when nil
          @notify = nil
        when :default
          @notify = Snipe::Beanstalk::Queue.activity_queue rescue nil
        else
          if bean_opt.respond_to?( :put ) then
            @notify = bean_opt
          else
            logger.error "the value given for :notify does not respond to put() => #{bean_opt.inspect}" 
            @notify = nil
          end
        end
        logger.info "Connected to beanstalkd server #{notify.name}" if can_notify?

        self.document.add_observer( self )
      end

      def can_notify?
        notify && notify.connected?
      end

      def notify_timer
        @notify_timer ||= ::Hitimes::Timer.new
      end

      def timer
        @timer ||= ::Hitimes::Timer.new
      end

      # only registered as an observer if there is a beanstalk server
      def update( *args )
        tweet = args.first
        notify_timer.measure {
          notify.put( Marshal.dump( tweet ) ) if can_notify?
        }
      end

      def parse_gnip_notification( fname )
        logger.info "Start parsing #{fname}"
        timer.measure {
          io = Zlib::GzipReader.open( fname )
          parse_io( io )
          io.close
        }
        mps = notify_timer.count / timer.duration

        logger.info "    notification : #{notify_timer.count} at #{"%0.3f" % notify_timer.rate} mps for a total of #{"%0.3f" % notify_timer.sum} seconds"
        logger.info "    total        : #{notify_timer.count} at #{"%0.3f" % mps} mps for a total of #{"%0.3f" % timer.duration} seconds"
        logger.info "Done parsing #{fname}"
      end
    end
  end
end
