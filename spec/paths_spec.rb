require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))

require 'snipe'

describe Snipe::Paths do
  before(:each) do
    @root_dir = File.expand_path( File.join( File.dirname( __FILE__ ), "..") )
    @root_dir += File::SEPARATOR
  end

  it "root dir should be correct" do
    Snipe::Paths.root_dir.should == @root_dir
    Snipe::Paths.root_dir[-1].chr.should == File::SEPARATOR
  end

  it "home dir should be correct" do
    Snipe::Paths.home_dir.should == @root_dir
    Snipe::Paths.home_dir[-1].chr.should == File::SEPARATOR
  end

  it "config_path should be correct" do
    Snipe::Paths.config_path.should == File.join(@root_dir, "config/")
  end

  it "data path should be correct" do
    Snipe::Paths.data_path.should == File.join(@root_dir, "data/")
  end

  it "lib path should be correct" do
    Snipe::Paths.lib_path.should == File.join(@root_dir, "lib/")
  end

  it "log path should be correct" do
    Snipe::Paths.log_path.should == File.join(@root_dir, "log/")
  end

  it "spec path should be correct" do
    Snipe::Paths.spec_path.should == File.join(@root_dir, "spec/")
  end

  it "tmp path should be correct" do
    Snipe::Paths.tmp_path.should == File.join(@root_dir, "tmp/")
  end

  describe "setting home_dir" do
    before( :each ) do
      @tmp_dir = make_temp_dir
      Snipe::Paths.home_dir = @tmp_dir
    end
    after( :each ) do
      FileUtils.rm_rf( @tmp_dir )
    end

    %w[ config data log tmp ].each do |d|
      check_path = "#{d}_path"
      it "affects the location of #{check_path}" do
        p = Snipe::Paths.send( check_path )
        p.should == ( File.join( @tmp_dir, d ) + File::SEPARATOR )
      end
    end

    %w[ lib spec ].each do |d|
      check_path = "#{d}_path"
      it "does not affect the location of #{check_path}" do
        p = Snipe::Paths.send( check_path )
        p.should == ( File.join( @root_dir, d ) + File::SEPARATOR )
      end
    end
  end
end
