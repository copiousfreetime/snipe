require 'daemons'
require 'snipe/gnip/parser'
module Snipe::Commands
  class Parse < Snipe::Command
    def parse_queue
      @parse_queue ||= Snipe::Queues.gnip_parse_queue
    end

    def parser
      unless defined? @parser
        @parser = Snipe::Gnip::Parser.new
        raise "not connected to activity queue" unless @parser.beanstalk_server
      end
      return @parser
    end

    def run
      loop do
        job = nil
        begin
          job = parse_queue.reserve
          fname = job.body
          parser.parse_gnip_notification( fname )
          job.delete
        rescue => e
          job.release unless job.nil?
          logger.error "Failure in processing a gnip file : #{e}"
        end
      end
    end
  end
end
