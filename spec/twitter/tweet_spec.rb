require File.expand_path( File.join( File.dirname( __FILE__ ),"..", "spec_helper.rb"))

require 'snipe'
require 'snipe/twitter/tweet'

describe Snipe::Twitter::Tweet do
  before( :each ) do
    @normal  = { "text"=>"como que manda blips aqui? num sei.", 
            "actor"=>"copiousfreetime", 
            "url"=>"http://twitter.com/statuses/show/1232707799.xml", 
            "action"=>"notice", 
            "at"=>"2009-02-19T23:11:27.000Z", 
            "source"=>"DestroyTwitter",
            "text" => "como que manda blips aqui? num sei."}

    @normal_t = Snipe::Twitter::Tweet.new( @normal )

    @reply = { "source"=>"twhirl", 
            "regarding"=>"http://twitter.com/statuses/show/1232640554.xml" ,
            "to"=>"BullishBeauty",
            "url"=>"http://twitter.com/statuses/show/1232709881.xml",
            "action"=>"notice", 
            "actor"=>"JeffreyLin",
            "at"=>"2009-02-21T00:36:54.000Z",
            "text" => "@JeffreyLin Haven't seen you post much lately.  Is everything ok with you?"}

    @reply_t = Snipe::Twitter::Tweet.new( @reply )

    @hashtag = { "source" => "web",
                 "actor" => "sophiabliu",
                 "action" => "notice",
                 "at"     => "2009-01-14T01:25:25.000Z",
                 "url"    => "http://twitter.com/status/show/1117167788.xml",
                 "text"   => "yesterday's blanket of snow has now covered the burned scars of the #boulderfire" }
    @hashtag_t = Snipe::Twitter::Tweet.new( @hashtag )
  end

  it "extacts the id from the url " do
    @normal_t.id.should == "1232707799"
  end

  it "extracts the source" do
    @normal_t.source.should == "DestroyTwitter"
  end

  it "has a reply url" do
    @reply_t.regarding.should == "http://twitter.com/statuses/show/1232640554.xml"
  end

  it "has a created time" do
    @reply_t.created_at.should == "2009-02-21T00:36:54.000Z"
  end

  it "has the tweet content" do
    @hashtag_t.text.should == "yesterday's blanket of snow has now covered the burned scars of the #boulderfire"
  end

  it "sees hashtags" do
    @hashtag_t.hashtags.should == [ "#boulderfire" ]
  end

  it "splits the message into token" do
    @normal_t.tokens.should == %w[ como que manda blips aqui? num sei. ]
  end

  it "knows everyone else mentioned in the tweet" do
    @reply_t.mentioning.should == [ "@JeffreyLin" ]
  end
end
