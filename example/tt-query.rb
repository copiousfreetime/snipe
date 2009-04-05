#!/usr/bin/env ruby

require 'tokyotyrant'
require 'rubygems'
require 'hitimes'

include TokyoTyrant

def dump_author_tweets( rdb, author )
  query = RDBQRY.new( rdb )
  query.addcond( "author", RDBQRY::QCSTREQ, author )
  #query.setorder( "at", RDBQRY::QOSTRASC )
  results = query.searchget
  puts "#{author} has #{results.size} tweets:"
  results.each do |r|
    #puts r.inspect
    puts "  #{r[""]} #{r['at']} : #{r['text']}"
  end
end

rdb = RDBTBL.new
rdb.open( "playground.copiousfreetime.org", 30303)
puts "Database has #{rdb.rnum} records"
author = ARGV.shift.strip
dump_author_tweets( rdb,  author )

