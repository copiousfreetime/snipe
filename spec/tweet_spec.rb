require File.expand_path( File.join( File.dirname( __FILE__ ), "spec_helper.rb"))

require 'snipe'
require 'snipe/tweet'

describe Snipe::Tweet::Fragment do
  it "has initializes with a name" do
    f = Snipe::Tweet::Fragment.new( 'blah' )
    f.name.should == 'blah'
  end

  it "initializes with a name and an array which becomes a hash of properties" do
    f = Snipe::Tweet::Fragment.new( 'blah', %w[ foo bar baz 42 ] )
    f.name.should == 'blah'
    f.attributes.size.should == 2
    f.attributes['foo'].should == 'bar'
    f.attributes['baz'].should == '42'
  end
end

describe Snipe::Tweet do
  before( :each ) do
    @normal  = [ "text","como que manda blips aqui? num sei.", 
            "actor","copiousfreetime", 
            "url","http://twitter.com/statuses/show/1232707799.xml", 
            "action","notice", 
            "at","2009-02-19T23:11:27.000Z", 
            "source","DestroyTwitter",
            "text" , "como que manda blips aqui? num sei."]
    @normal_t = Snipe::Tweet.new( @normal )

    @reply = [ "source","twhirl", 
            "regardingurl","http://twitter.com/statuses/show/1232640554.xml" ,
            "to","BullishBeauty",
            "url","http://twitter.com/statuses/show/1232709881.xml",
            "action","notice", 
            "actor","JeffreyLin",
            "at","2009-02-21T00:36:54.000Z",
            "text" , "@JeffreyLin Haven't seen you post much lately.  Is everything ok with you?"]
    @reply_t = Snipe::Tweet.new( @reply )

    @hashtag = [ "source" , "web",
                 "actor" , "sophiabliu",
                 "action" , "notice",
                 "at"     , "2009-01-14T01:25:25.000Z",
                 "url"    , "http://twitter.com/status/show/1117167788.xml",
                 "text"   , "yesterday's blanket of snow has now covered the burned scars of the #boulderfire" ]
    @hashtag_t = Snipe::Tweet.new( @hashtag )

    @urls_t = Snipe::Tweet.new( @hashtag )
  end

  it "has the 'Tweet' type" do
    @normal_t.type.should == "Tweet"
  end

  it "extacts the id from the url " do
    @normal_t.status_id.should == "1232707799"
  end

  it "extracts the source" do
    @normal_t.source.should == "DestroyTwitter"
  end

  it "extracts the urls from the text" do 
    @urls_t.text = "here's the original of the photo @thecupboulder backroom  http://is.gd/kPvm"
    @urls_t.urls.size.should == 1
    @urls_t.urls.first.should == "http://is.gd/kPvm"
  end

  it "has a reply url" do
    @reply_t.regardingurl.should == "http://twitter.com/statuses/show/1232640554.xml"
  end

  it "has a created time" do
    @reply_t.at.should == "2009-02-21T00:36:54.000Z"
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
    @reply_t.mentions.should == [ "@JeffreyLin" ]
  end

  it "updates mentioning when text is set" do
    @reply_t.text = "This is something that @atmos and @aneiro said"
    @reply_t.mentions.should == %w[ @atmos @aneiro ]
  end

  it "updates hashtags when text is set" do
    @hashtag_t.text = "What did you say about #thatstuff #overthere ?"
    @hashtag_t.hashtags.should == %w[ #thatstuff #overthere ]
  end

  it "has the post_at as an mjd_stamp" do
    @hashtag_t.post_at.should =~ /\d{5}\.\d{5}/
  end

  it "has the post_date as an mjd" do
    @normal_t.post_date.should == 54881
  end

  it "has a key" do
    @hashtag_t.key.should == "tweet/1117167788"
  end

  it "converts to a hash" do
    @hashtag_t.to_hash.should be_instance_of( Hash )
  end

  it "raises an error in hash conversion if it can't figure out what type to use" do
    @hashtag_t.split_at = Object.new
    lambda { @hashtag_t.to_hash }.should raise_error(StandardError, /Unknown type conversion/)
  end

  it "creates an author snapshot key" do
    @normal_t.author_snapshot_key.should == "author/copiousfreetime/54881"
  end
end
