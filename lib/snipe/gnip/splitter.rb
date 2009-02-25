require 'nokogiri'
require 'snipe/gnip/notification_document'
require 'zlib'
require 'snipe/beanstalk/queue'
module Snipe
  module Gnip
    class Splitter < ::Nokogiri::XML::SAX::Parser
      attr_accessor :scrape

      def self.split_gnip_notification( fname )
        p = self.new
        p.split_gnip_notification( fname )
        return p
      end

      def self.default_opts
        { :doc => Gnip::NotificationDocument.new,
          :scrape => :default }
      end
      
      def logger
        Logging::Logger[self]
      end

      def initialize( opts = {} )
        opts = Splitter.default_opts.merge( opts )
        doc = opts.delete( :doc )

        super( doc )
        case bean_opt = opts[:scrape]
        when nil
          @scrape = nil
        when :default
          @scrape = Snipe::Beanstalk::Queue.scrape_queue rescue nil
        else
          if bean_opt.respond_to?( :put ) then
            @scrape = bean_opt
          else
            logger.error "the value given for :scrape does not respond to put() => #{bean_opt.inspect}" 
            @scrape = nil
          end
        end
        logger.info "Connected to beanstalkd server #{scrape.name}" if can_scrape?

        self.document.add_observer( self )
      end

      def can_scrape?
        scrape && scrape.connected?
      end

      def scrape_timer
        @scrape_timer ||= ::Hitimes::Timer.new
      end

      def timer
        @timer ||= ::Hitimes::Timer.new
      end

      # only registered as an observer if there is a beanstalk server
      def update( *args )
        tweet = args.first
        scrape_timer.measure {
          scrape.put( Marshal.dump( tweet ) ) if can_scrape?
        }
      end

      def split_gnip_notification( fname )
        logger.info "Start parsing #{fname}"
        timer.measure {
          io = Zlib::GzipReader.open( fname )
          parse_io( io )
          io.close
        }
        mps = scrape_timer.count / timer.duration

        logger.info "    notification : #{scrape_timer.count} at #{"%0.3f" % scrape_timer.rate} mps for a total of #{"%0.3f" % scrape_timer.sum} seconds"
        logger.info "    total        : #{scrape_timer.count} at #{"%0.3f" % mps} mps for a total of #{"%0.3f" % timer.duration} seconds"
        logger.info "Done parsing #{fname}"
      end
    end
  end
end
