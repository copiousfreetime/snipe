require File.expand_path( File.join( File.dirname( __FILE__ ),"..", "spec_helper.rb"))

require 'snipe'
require 'snipe/twitter/fetcher'

describe Snipe::Twitter::Fetcher do
  before( :each ) do
    @cft = [ "actor" ,"copiousfreetime" ,
             "url"   ,"http://twitter.com/status/show/1221929390.xml",
             "action","notice" ,
             "at"    ,"2009-02-18T06:08:05.000Z" ,
             "source","twhirl" ]

    @event = ::Snipe::Gnip::Event.new( @cft )
    @fetcher = Snipe::Twitter::Fetcher.new
  end

  it " fetchs the text " do
    @fetcher.fetch_tweet( @event ).text.should == "Green Tea Vodka + Green Tea = joy"
  end

  it "fetches the text via html" do
    @fetcher.fetch_tweet_from_html( @event ).text.should == "Green Tea Vodka + Green Tea = joy"
  end
  
  it "fetches the text via xml" do
    @fetcher.fetch_tweet_from_xml( @event ).text.should == "Green Tea Vodka + Green Tea = joy"
  end
end
