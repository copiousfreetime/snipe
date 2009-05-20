$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'
require 'snipe/couchdb/tweet'
require 'snipe/tweet_fetcher'

Snipe::Log.init
fetcher = Snipe::TweetFetcher.new
edata = %w[ source DestroyTwitter url http://twitter.com/statuses/show/1232707799.xml action notice actor copiousfreetime at 2009-02-19T23:11:27.000Z ]
tweet = Snipe::CouchDB::Tweet.new( edata )

tweet.text = fetcher.fetch_text( tweet )
puts "#{tweet.actor} sent '#{tweet.text}' using #{tweet.source} on #{tweet.at}"
