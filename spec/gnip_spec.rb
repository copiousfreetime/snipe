require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/gnip/parser'

describe Snipe::Gnip::Parser do
  before( :each ) do
    @gz_file = Snipe::Paths.spec_path( "data/sample.xml.gz" )
  end

  it "Parser#parse_gnip_notifications" do
    parser = ::Snipe::Gnip::Parser.new( :beanstalk_server => nil ) 
    parser.parse_gnip_notification( @gz_file )
    parser.document.timer.stats.count.should == parser.put_timer.count
    parser.put_timer.count.should == 1345
  end

  it "Parser.parse_gnip_notifications" do
    parser = Snipe::Gnip::Parser.parse_gnip_notification( @gz_file )
    parser.document.timer.stats.count.should == 1345
  end

  it "logs an error if unable to connect to the queue server" do
    parser = Snipe::Gnip::Parser.parse_gnip_notification( @gz_file )
    log = spec_log
    log.should =~ /Failure connecting to .* on tube .*/
  end

  it "logs an error if give something a beanstalk option does not respond to put" do
    parser = ::Snipe::Gnip::Parser.new( :beanstalk_server => Object.new )
    spec_log.should =~ /the value given for :beanstalkd_server does not respond to put/
  end

  it "calls put on the beanstalk server" do
    class DeadQueue 
      attr_reader :count
      def initialize
        @count = 0
      end
      def addr() "dead"; end
      def list_tube_used() "dead"; end
      def put( *args )
        @count += 1
      end
    end
    parser = ::Snipe::Gnip::Parser.new( :beanstalk_server => DeadQueue.new )
    parser.parse_gnip_notification( @gz_file )
    parser.beanstalk_server.count.should == 1345
  end
end
