#!/usr/bin/env ruby

$: << File.expand_path( File.join( File.dirname( __FILE__ ), "..", "lib" ) )

require 'rubygems'
require 'tokyotyrant'

host = ARGV.shift || "127.0.0.1"
port = ARGV.shift || 30303

Db = TokyoTyrant::RDBTBL.new
Db.open( host, port )

Db.stat.split("\n").sort.each do |line|
  k,v = line.split("\t")
  if %w[ rnum size ].include?(k ) then
    pre, post = v.split(".")
    pre = pre.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
    v = pre
    v += ".#{post}" if post
  end
  puts "#{k.ljust(20, ".")} #{v}"
end
