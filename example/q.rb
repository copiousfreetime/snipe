$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'

Snipe::Log.init
gz_file = Snipe::Paths.spec_path( "data/sample.xml.gz" )
Snipe::Gnip::Splitter.split_gnip_notification( gz_file )

