require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/gnip/parser'

describe Snipe::Gnip::Parser do
  before( :each ) do
    @gz_file = Snipe::Paths.spec_path( "data/sample.xml.gz" )
  end

  it "parses the file" do
    parser = ::Snipe::Gnip::Parser.new
    parser.parse_gnip_notification( @gz_file )
    parser.document.timer.stats.count.should == 1345
  end
end
