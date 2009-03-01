require 'nokogiri'
require 'snipe/gnip/notification_document'
require 'zlib'
require 'snipe/beanstalk/queue'
module Snipe
  module Gnip
    class Splitter < ::Nokogiri::XML::SAX::Parser
      attr_accessor :scrape_queue

      # the time the file that is being processed was written to the filesystem
      # this is the 'consume' time since its when we pulled it down from gnip
      attr_reader :consume_mjd_stamp

      def self.split_gnip_notification( fname )
        p = self.new
        p.split_gnip_notification( fname )
        return p
      end

      def self.default_opts
        { :doc => Gnip::NotificationDocument.new,
          :scrape_queue => :default }
      end
      
      def logger
        Logging::Logger[self]
      end

      def initialize( opts = {} )
        opts = Splitter.default_opts.merge( opts )
        doc = opts.delete( :doc )

        super( doc )
        case bean_opt = opts[:scrape_queue]
        when nil
          @scrape_queue = nil
        when :default
          @scrape_queue = Snipe::Beanstalk::Queue.scrape_queue rescue nil
        else
          if bean_opt.respond_to?( :put ) then
            @scrape_queue = bean_opt
          else
            logger.error "the value given for :scrape_queue does not respond to put() => #{bean_opt.inspect}" 
            @scrape_queue = nil
          end
        end
        logger.info "Connected to beanstalkd server #{scrape_queue.name}" if can_put_to_scrape_queue?

        self.document.add_observer( self )
      end

      def can_put_to_scrape_queue?
        scrape_queue && scrape_queue.connected?
      end

      def scrape_queue_put_timer
        @scrape_queue_put_timer ||= ::Hitimes::Timer.new
      end

      def timer
        @timer ||= ::Hitimes::Timer.new
      end

      # only registered as an observer if there is a beanstalk server
      def update( *args )
        tweet = args.first
        tweet.consume_at = consume_mjd_stamp
        scrape_queue_put_timer.measure {
          scrape_queue.put( Marshal.dump( tweet ) ) if can_put_to_scrape_queue?
        }
      end

      def split_gnip_notification( fname )
        logger.info "Start parsing #{fname}"
        @consume_mjd_stamp = File.mtime( fname ).mjd_stamp

        timer.measure {
          io = Zlib::GzipReader.open( fname )
          parse_io( io )
          io.close
        }
        mps = scrape_queue_put_timer.count / timer.duration

        logger.info "    notification : #{scrape_queue_put_timer.count} at #{"%0.3f" % scrape_queue_put_timer.rate} mps for a total of #{"%0.3f" % scrape_queue_put_timer.sum} seconds"
        logger.info "    total        : #{timer.count} at #{"%0.3f" % mps} mps for a total of #{"%0.3f" % timer.duration} seconds"
        logger.info "Done parsing #{fname}"
      end
    end
  end
end
