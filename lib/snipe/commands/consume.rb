require 'daemons'
require 'snipe/gnip/consumer'
module Snipe::Commands

  # command used to notify of files that have been downloaded and need to be
  # parsed.
  class Consume < Snipe::Command
    def splitter
      @splitter ||= Snipe::Beanstalk::Queue.split_queue
    end

    def run
      consumer = ::Snipe::Gnip::Consumer.new
      consumer.add_observer( self )
      consumer.limit = options['limit'] 
      consumer.start
    end

    def update( *args )
      path = args.first
      splitter.put( path ) if splitter
    end
  end
end
