require File.expand_path( File.join( File.dirname( __FILE__ ),"..", "spec_helper.rb"))

require 'snipe'
require 'snipe/couchdb/tweet_store'
require 'snipe/couchdb/tweet'

describe Snipe::CouchDB::TweetStore do
  before( :each ) do
    @normal  = { "text"=>"como que manda blips aqui? num sei.", 
            "actor"=>"copiousfreetime", 
            "url"=>"http://twitter.com/statuses/show/1232707799.xml", 
            "action"=>"notice", 
            "at"=>"2009-02-19T23:11:27.000Z", 
            "source"=>"DestroyTwitter",
            "text" => "como que manda blips aqui? num sei."}

    @normal_t = Snipe::CouchDB::Tweet.new( @normal )

    @reply = { "source"=>"twhirl", 
            "regarding"=>"http://twitter.com/statuses/show/1232640554.xml" ,
            "to"=>"BullishBeauty",
            "url"=>"http://twitter.com/statuses/show/1232709881.xml",
            "action"=>"notice", 
            "actor"=>"JeffreyLin",
            "at"=>"2009-02-21T00:36:54.000Z",
            "text" => "@JeffreyLin Haven't seen you post much lately.  Is everything ok with you?"}

    @reply_t = Snipe::CouchDB::Tweet.new( @reply )

    @hashtag = { "source" => "web",
                 "actor" => "sophiabliu",
                 "action" => "notice",
                 "at"     => "2009-01-14T01:25:25.000Z",
                 "url"    => "http://twitter.com/status/show/1117167788.xml",
                 "text"   => "yesterday's blanket of snow has now covered the burned scars of the #boulderfire" }
    @hashtag_t = Snipe::CouchDB::Tweet.new( @hashtag )

    @store  = ::Snipe::CouchDB::TweetStore.new("spec_db")
  end

  after( :each ) do 
    @store.delete!
  end

  it "has a default server" do
    ::Snipe::CouchDB::TweetStore.server.uri.should == "http://localhost:5984"
  end

  it "creates the db if it doesn't exist" do
    @store.info["db_name"].should == "spec_db" 
  end

  it "stores a document" do
    @normal_t["_id"].should be_nil
    @store.save( @normal_t )
    @store.info['doc_count'].should == 1
    @normal_t["_id"].should_not be_nil

  end
end

