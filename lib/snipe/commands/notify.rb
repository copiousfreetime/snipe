require 'daemons'
require 'snipe/gnip/scraper'
module Snipe::Commands
  class Notify < Snipe::Command
    def run
      scraper = ::Snipe::Gnip::Scraper.new
      scraper.start
    end
  end
end
