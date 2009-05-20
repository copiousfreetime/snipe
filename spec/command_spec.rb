require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))

require 'snipe/command'

class Junk < Snipe::Command; end

describe Snipe::Command do
  before( :each ) do
    @cmd = Snipe::Command.new
  end

  it "has a command name" do
    @cmd.command_name.should == "command"
  end

  it "can log" do
    @cmd.logger.info "this is a log statement"
    spec_log.should =~ /this is a log statement/
  end

  it "cannot be run" do
    lambda { @cmd.run }.should raise_error( Snipe::Command::Error, /Unknown command `command`/ )
  end

  it "registers inherited classes" do
    Snipe::Command.commands.should be_include( Junk )
    Snipe::Command.commands.delete( Junk )
    Snipe::Command.commands.should_not be_include(Junk)
  end

  it "classes cannot be run without implementing 'run'" do
    j = Junk.new
    j.respond_to?(:run).should == true
    lambda { j.run }.should raise_error( Snipe::Command::Error, /Unknown command `junk`/)
  end
end
