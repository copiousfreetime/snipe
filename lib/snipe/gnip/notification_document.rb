require 'hitimes'
require 'nokogiri'
require 'snipe/tweet'
require 'observer'
require 'stringio'

module Snipe
  module Gnip
    class NotificationDocument < ::Nokogiri::XML::SAX::Document

      include Observable

      attr_reader :timer
      attr_reader :interval

      attr_reader :fragment_stack

      def initialize
        @timer = ::Hitimes::Timer.new
        @interval =  ::Hitimes::Interval.new
        @fragment_stack = []
        @current_tweet = nil
      end

      def current_fragment
        @fragment_stack.last
      end

      #---
      # Call back methods
      #---
      def start_document
        @interval.start
      end


      def start_element( name, attrs = [])
        case name
        when "activities"
          # do nothing
          return
        when "action" 
          return
        when "activity"
          @timer.start
          @current_tweet = Tweet.new
        else
          fragment_stack.push Tweet::Fragment.new( name.downcase, attrs )
        end
      end

      def characters( string )
        unless fragment_stack.empty?
          current_fragment.add_text( string )
        end
      end

      def end_element( name )
        case name
        when "activities"
          # do nothing
          return
        when "action" 
          return
        when "activity"
          raise "Woah!  Parsing error at 'activity' closing tag: #{f.inspect}" unless fragment_stack.empty?
          self.changed
          self.notify_observers( @current_tweet )
          @current_tweet = nil
          @timer.stop
        else
          f = fragment_stack.pop
          if fragment_stack.empty?
            @current_tweet.add_fragment( f )
          else
            current_fragment.children << f
          end
        end
      end

      def end_document
        @interval.stop
        nil
      end
    end
  end
end
