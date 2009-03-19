#!/usr/bin/env ruby


require 'rubygems'
require 'tokyotyrant'

host = ARGV.shift || "127.0.0.1"
port = ARGV.shift || 1978

Db = TokyoTyrant::RDBTBL.new
Db.open( host, port )

Db.stat.split("\n").sort.each do |line|
  k,v = line.split("\t")
  puts "#{k.ljust(20, ".")} #{v}"
end
