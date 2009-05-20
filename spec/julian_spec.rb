require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/julian'

describe Snipe::Julian do

  it "can round trip a time from now to modified julan time and back" do
    only_sec  = Time.at( Time.now.utc.to_i ).utc
    today_mjd = only_sec.mjd_stamp
    utc_round = Time.from_mjd_stamp( today_mjd )
    utc_round.should == only_sec
  end

  it "can return the current time as an mjd_stamp" do
    n = Time.now_as_mjd_stamp
    n.should =~ /\d{5}\.\d{5}/
  end

  it "can create a date from an mjd "  do
    utc = Time.now.utc
    now_mjd = utc.mjd
    t = Time.from_mjd( now_mjd )

    ut = Time.gm( utc.year, utc.month, utc.day )
    t.should == ut
  end
end

