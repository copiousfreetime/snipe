require 'daemons'
require 'snipe/gnip/parser'
require 'snipe/beanstalk/observer'

module Snipe::Commands
  class Parse < Snipe::Command
    def parse_queue_observer
      @parse_queue_observer ||= Snipe::Beanstalk::Observer.parse_observer
    end

    def parser
      @parser ||= Snipe::Gnip::Parser.new
    end

    # callec by the beanstalk observer when an item is pulled off the queue
    def update( fname )
      parser.parse_gnip_notification( fname )
    end

    def run
      if parse_queue_observer then
        parse_queue_observer.add_observer( self )
        parse_queue_observer.observe
      else
        logger.error "Unable to parse, not able to observe the parse queue"
      end
    end
  end
end
