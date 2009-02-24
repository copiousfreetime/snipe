require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/gnip/splitter'

describe Snipe::Gnip::Splitter do
  before( :each ) do
    @gz_file = Snipe::Paths.spec_path( "data/sample.xml.gz" )
  end

  it "Splitter#split_gnip_notifications" do
    splitter = ::Snipe::Gnip::Splitter.new( :notify => nil ) 
    splitter.split_gnip_notification( @gz_file )
    splitter.document.timer.stats.count.should == splitter.split_timer.count
    splitter.split_timer.count.should == 1495
  end

  it "Splitter.split_gnip_notifications" do
    splitter = Snipe::Gnip::Splitter.split_gnip_notification( @gz_file )
    splitter.document.timer.stats.count.should == 1495
  end

  it "logs an error if unable to connect to the queue server" do
    splitter = Snipe::Gnip::Splitter.split_gnip_notification( @gz_file )
    spec_log.should =~ /Failure connecting to .*:\d+\/\w+/
  end

  it "logs an error if give something a beanstalk option does not respond to put" do
    splitter = ::Snipe::Gnip::Splitter.new( :split => Object.new )
    spec_log.should =~ /the value given for :split does not respond to put/
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
    splitter = ::Snipe::Gnip::Splitter.new( :split => DeadQueue.new )
    splitter.split_gnip_notification( @gz_file )
    splitter.split.count.should == 1345
  end
end
