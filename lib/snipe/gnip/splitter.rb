require 'nokogiri'
require 'snipe/gnip/document'
require 'zlib'
require 'snipe/beanstalk/queue'
module Snipe
  module Gnip
    class Splitter < ::Nokogiri::XML::SAX::Parser
      attr_accessor :split

      def self.split_gnip_notification( fname )
        p = self.new
        p.split_gnip_notification( fname )
        return p
      end

      def self.default_opts
        { :doc => Gnip::Document.new,
          :split => :default }
      end
      
      def logger
        Logging::Logger[self]
      end

      def initialize( opts = {} )
        opts = Splitter.default_opts.merge( opts )
        doc = opts.delete( :doc )

        super( doc )
        case bean_opt = opts[:split]
        when nil
          @split = nil
        when :default
          @split = Snipe::Beanstalk::Queue.split_queue rescue nil
        else
          if bean_opt.respond_to?( :put ) then
            @split = bean_opt
          else
            logger.error "the value given for :split does not respond to put() => #{bean_opt.inspect}" 
            @split = nil
          end
        end
        logger.info "Connected to beanstalkd server #{split.name}" if can_split?

        self.document.add_observer( self )
      end

      def can_split?
        split && split.connected?
      end

      def split_timer
        @split_timer ||= ::Hitimes::Timer.new
      end

      def timer
        @timer ||= ::Hitimes::Timer.new
      end

      # only registered as an observer if there is a beanstalk server
      def update( *args )
        tweet = args.first
        split_timer.measure {
          split.put( Marshal.dump( tweet ) ) if can_split?
        }
      end

      def split_gnip_notification( fname )
        logger.info "Start parsing #{fname}"
        timer.measure {
          io = Zlib::GzipReader.open( fname )
          parse_io( io )
          io.close
        }
        mps = split_timer.count / timer.duration

        logger.info "    notification : #{split_timer.count} at #{"%0.3f" % split_timer.rate} mps for a total of #{"%0.3f" % split_timer.sum} seconds"
        logger.info "    total        : #{split_timer.count} at #{"%0.3f" % mps} mps for a total of #{"%0.3f" % timer.duration} seconds"
        logger.info "Done parsing #{fname}"
      end
    end
  end
end
