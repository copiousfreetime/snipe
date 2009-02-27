#!/usr/bin/env ruby
#

require 'rubygems'
require 'rest_client'
require 'json'

Db = RestClient::Resource.new("http://localhost:1978")

def dump_info( db ) 
  puts "Author Tweet Count:"
  JSON.parse( db['authors'].get ).each do |k,_|
    puts "  #{k.ljust(20, ".")} #{db["author/#{k}"].get }"
  end
 
  puts "Source Tweet Count:"
  JSON.parse( db['sources'].get ).each do | k,_ |
    puts "  #{k.ljust(20, ".")} #{db["source/#{k}"].get } tweets"
  end
end


loop do
  puts "-<>-" * 20
  dump_info( Db )
  sleep 10
end
