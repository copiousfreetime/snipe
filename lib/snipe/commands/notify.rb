require 'daemons'
require 'snipe/gnip/scraper'
module Snipe::Commands

  # command used to notify of files that have been downloaded and need to be
  # parsed.
  class Notify < Snipe::Command
    def notifier
      @notifier ||= Snipe::Beanstalk::Queue.parse_queue
    end

    def run
      scraper = ::Snipe::Gnip::Scraper.new
      scraper.add_observer( self )
      scraper.start
    end

    def update( *args )
      path = args.first
      notifier.put( path ) if notifier
    end
  end
end
