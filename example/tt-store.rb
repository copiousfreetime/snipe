#!/usr/bin/env ruby

require 'rubygems'
require 'rest_client'
require 'json'
require 'hitimes'

# start ttserver with
#   cd <project root> 
#   export LUA_PATH=${PWD}/lua/?/?.lua
#   ttserver -ld -ext lua/snipe.lua '*'

#RestClient.log = 'stderr'
db = RestClient::Resource.new("http://localhost:1978")

words = IO.readlines( "/usr/share/dict/words" )

timer = Hitimes::Timer.new
authors = %w[ me myself and I ]
sources = %w[ TweetDeck web Twitterific ]

words.each_with_index do |word, idx|

  timer.measure {
    payload = { "author" => authors[idx % authors.size ],
                "text"   => "This is a tweet",
                "source" => sources[idx % sources.size ],
                "id"     => idx
               }

    j_payload = JSON.generate( payload )

    db["tweet/#{idx}"].post( j_payload, { 'X-TT-XNAME' => 'store_tweet', 'X-TT-XOPTS' => 1 } )
    #kdb["tweet/#{idx}"].put( j_payload )
  }

  if timer.count % 1000  == 0 then
    puts timer.stats.to_hash.inspect
  end
end

puts timer.stats.to_hash.inspect


