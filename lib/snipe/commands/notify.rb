require 'daemons'
require 'snipe/gnip/scraper'
module Snipe::Commands
  class Notify < Snipe::Command
    def beanstalk_server
      @beanstalk_server ||= Snipe::Queues.gnip_parse_queue
    end

    def run
      scraper = ::Snipe::Gnip::Scraper.new
      scraper.add_observer( self )
      scraper.start
    end

    def update( *args )
      path = args.first
      beanstalk_server.put( path ) if beanstalk_server
    end
  end
end
