require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/julian'

describe Snipe::Julian do

  it "can round trip a time from now to modified julan time and back" do
    only_sec  = Time.at( Time.now.utc.to_i ).utc
    today_mjd = only_sec.mjd_stamp
    utc_round = Time.from_mjd_stamp( today_mjd )
    utc_round.should == only_sec
  end
end

