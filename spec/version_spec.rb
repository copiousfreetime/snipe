require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/version'

describe "Snipe::Version" do
  it "has a string representation like #.#.#" do
    Snipe::Version.to_s.should =~ /\d+\.\d+\.\d+/
    Snipe::VERSION.should =~ /\d+\.\d+\.\d+/
  end

  it "has a version array " do
    a = Snipe::Version.to_a
    a.size.should == 3
    a.each do |v|
      v.should be_kind_of( Integer )
      v.should >= 0
    end
  end

  it "has a version hash" do
    h = Snipe::Version.to_hash
    h.size.should == 3
    [ :major, :minor, :build ].each do |k|
      h[k].should_not be_nil
      h[k].should be_kind_of( Integer )
      h[k].should >= 0
    end
  end
end
