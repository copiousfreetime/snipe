$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'
require 'snipe/twitter/fetcher'

Snipe::Log.init
fetcher = Snipe::Twitter::Fetcher.new
#edata = %w[ source DestroyTwitter url http://twitter.com/statuses/show/1228516325.xml action notice actor copiousfreetime at 2009-02-19T23:11:27.000Z ]
edata = %w[ source DestroyTwitter url http://twitter.com/statuses/show/1232707799.xml action notice actor copiousfreetime at 2009-02-19T23:11:27.000Z ]
event = Snipe::Gnip::Event.new( edata )

tweet = fetcher.fetch_tweet( event )
puts "#{tweet.author} sent '#{tweet.text}' using #{tweet.source} on #{tweet.created_at}"
#puts tweet.inspect
#tweet = fetcher.fetch_tweet_from_xml( event )
#tweet2 = fetcher.fetch_tweet_from_html( event )
#puts " xml : '#{tweet}'"
#puts "html : '#{tweet}'"
