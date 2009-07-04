#!/usr/bin/env ruby

$: <<  File.expand_path( File.join( File.dirname( __FILE__ ), "..", "lib" ) )
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
#rdb.open( "playground.copiousfreetime.org", 30303)
rdb.open( "localhost", 30303)
puts "Database has #{rdb.rnum} records"
author = ARGV.shift.strip
dump_author_tweets( rdb,  author )

