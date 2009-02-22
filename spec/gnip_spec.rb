require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/gnip/parser'

describe Snipe::Gnip::Parser do
  before( :each ) do
    @gz_file = Snipe::Paths.spec_path( "data/sample.xml.gz" )
  end

  it "Parser#parse_gnip_notifications" do
    parser = ::Snipe::Gnip::Parser.new( :notify => nil ) 
    parser.parse_gnip_notification( @gz_file )
    parser.document.timer.stats.count.should == parser.notify_timer.count
    parser.notify_timer.count.should == 1345
  end

  it "Parser.parse_gnip_notifications" do
    parser = Snipe::Gnip::Parser.parse_gnip_notification( @gz_file )
    parser.document.timer.stats.count.should == 1345
  end

  it "logs an error if unable to connect to the queue server" do
    parser = Snipe::Gnip::Parser.parse_gnip_notification( @gz_file )
    spec_log.should =~ /Failure connecting to .*:\d+\/\w+/
  end

  it "logs an error if give something a beanstalk option does not respond to put" do
    parser = ::Snipe::Gnip::Parser.new( :notify => Object.new )
    spec_log.should =~ /the value given for :notify does not respond to put/
  end

  it "calls put on the beanstalk server" do
    class DeadQueue 
      attr_reader :count
      def initialize
        @count = 0
      end
      def connected?() true; end
      def name() "dead/dead"; end
      def put( *args )
        @count += 1
      end
    end
    parser = ::Snipe::Gnip::Parser.new( :notify => DeadQueue.new )
    parser.parse_gnip_notification( @gz_file )
    parser.notify.count.should == 1345
  end
end
