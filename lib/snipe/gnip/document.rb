require 'hitimes'
require 'nokogiri'
require 'snipe/couchdb/tweet'
require 'observer'
module Snipe
  module Gnip
    class Document < ::Nokogiri::XML::SAX::Document
      include Observable

      attr_reader :timer
      attr_reader :interval

      def initialize
        @timer = ::Hitimes::Timer.new
        @interval =  ::Hitimes::Interval.new
      end

      def start_document
        @interval.start
      end

      def start_element( name, attrs = [])
        return unless name == "activity"
        @timer.start
        tweet = ::Snipe::CouchDB::Tweet.new( attrs )
        self.changed
        self.notify_observers( tweet )
      end

      def end_element( name )
        @timer.stop
        nil
      end

      def end_document
        @interval.stop
        nil
      end
    end
  end
end
