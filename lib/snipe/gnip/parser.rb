require 'nokogiri'
require 'snipe/gnip/document'
require 'zlib'
module Snipe
  module Gnip
    class Parser < ::Nokogiri::XML::SAX::Parser
      attr_accessor :document
      def initialize( doc = Gnip::Document.new )
        super
      end

      def parse_gnip_notification( fname )
        io = Zlib::GzipReader.open( fname )
        parse_io( io )
        io.close
      end
    end
  end
end
