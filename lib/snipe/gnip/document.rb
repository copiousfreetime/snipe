require 'hitimes'
require 'nokogiri'
require 'snipe/gnip/event'
module Snipe
  module Gnip
    class Document < ::Nokogiri::XML::SAX::Document
      attr_reader :timer
      attr_reader :interval
      def self.from_gz( path )
        new( Zlib::GzipReader.open( "data/200902210100.xml.gz" ).read )
      end
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
        @event = Gnip::Event.new( attrs )
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
