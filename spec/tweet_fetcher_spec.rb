require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))

require 'snipe'
require 'snipe/tweet_fetcher'

describe Snipe::TweetFetcher do
  before( :each ) do
    @cft = [ "actor" ,"copiousfreetime" ,
             "url"   ,"http://twitter.com/status/show/1221929390.xml",
             "action","notice" ,
             "at"    ,"2009-02-18T06:08:05.000Z" ,
             "source","twhirl" ]

    @tweet = ::Snipe::CouchDB::Tweet.new( @cft )
    @fetcher = Snipe::TweetFetcher.new
  end

  it "fetchs the text " do
    @fetcher.fetch_text( @tweet ).should == "Green Tea Vodka + Green Tea = joy"
  end

  it "fetches the text via html" do
    @fetcher.fetch_text_from_html( @tweet ).should == "Green Tea Vodka + Green Tea = joy"
  end
  
  it "fetches the text via xml" do
    @fetcher.fetch_text_from_xml( @tweet ).should == "Green Tea Vodka + Green Tea = joy"
  end
end
