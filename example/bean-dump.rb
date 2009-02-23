#!/usr/bin/env ruby
require 'rubygems'
require 'beanstalk-client'

conn = ::Beanstalk::Connection.new( "localhost:11300" )

tubes = conn.list_tubes.sort
tubes.each do |t|
  stats = conn.stats_tube( t )
  stats.delete('name')
  puts "#{t}:"
  puts "=" * (t.length + 1)
  stats.keys.sort.each do |k|
    puts "  #{k.ljust(30, ".")} #{stats[k]}"
  end
  puts
end
