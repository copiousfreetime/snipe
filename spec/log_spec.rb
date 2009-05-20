require 'snipe'

describe Snipe::Log do
  before( :each ) do
    @log = Snipe::Log
  end

  after( :each ) do
    FileUtils.rm_f( @log.filename )
  end

  it "has a default directory of Paths#log_path" do
    @log.directory.should == Snipe::Paths.log_path
  end

  it "has a default file of Paths#log_path / snipe.log" do
    @log.filename.should == File.join( Snipe::Paths.log_path, "snipe.log" )
  end

  it "can set and retrieve a log leve" do
    @log.level.should == 0
    @log.level = "error"
    @log.level.should == 3
    @log.level = 0
  end

  it "has a top level Snipe logger" do
    Snipe.logger.should_not be_nil
    Snipe.logger.info "Testing the Snipe.logger"
    spec_log.should =~ / Snipe /
    spec_log.should =~ / Testing the Snipe.logger/
  end

  it "logs to a file" do
    Snipe::Log.init
    Snipe::Log.level.should == 1
    Snipe.logger.info "This is a test log into a file"
    log_lines = IO.readlines( @log.filename )
    log_lines.size.should == 2
    log_lines.first.should =~ /Snipe version \d+\.\d+\.\d+/
    log_lines[1].should =~ /This is a test log into a file/
  end
end
