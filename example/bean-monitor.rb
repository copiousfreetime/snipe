#!/usr/bin/env ruby
require 'rubygems'
require 'beanstalk-client'

conn = ::Beanstalk::Connection.new( "localhost:11300" )

loop do
  tubes = conn.list_tubes.sort
  tubes.each do |t|
    next if t == "default"
    stats = conn.stats_tube( t )
    puts "#{t.rjust(15)} : current-jobs-ready -> #{stats['current-jobs-ready']} current-jobs-reserved -> #{stats['current-jobs-reserved']} total-jobs #{stats['total-jobs']}"
  end
  puts "-<>-" * 20
  sleep 1
end
