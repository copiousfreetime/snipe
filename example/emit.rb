require 'rubygems'
$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'
require 'snipe/gnip/splitter'

Snipe::Log.init
splitter =  Snipe::Gnip::Splitter.new
fname = ARGV.shift
puts "Splitting #{fname}"
splitter.split_gnip_notification( fname )

