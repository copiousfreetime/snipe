require 'daemons'
require 'snipe/gnip/splitter'
require 'snipe/beanstalk/observer'

module Snipe::Commands
  class Split < Snipe::Command
    def split_queue_observer
      @split_queue_observer ||= Snipe::Beanstalk::Observer.split_observer
    end

    def splitter
      @splitter ||= Snipe::Gnip::Splitter.new
    end
   
    def shutdown
      split_queue_observer.stop if split_queue_observer
    end


    # callec by the beanstalk observer when an item is pulled off the queue
    def update( fname )
      splitter.split_gnip_notification( fname )
    end

    def run
      if split_queue_observer then
        split_queue_observer.add_observer( self )
        split_queue_observer.observe( options['limit'] )
      else
        logger.error "Unable to split, not able to observe the split queue"
      end
    end
  end
end
