#-----------------------------------------------------------------------------
# Daemonizable is mostly code from thin, http://code.macournoyer.com/thin/
# altered to suite snipe, and as such, including Thin's copyright in this file
#-<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--
#
# Copyright (c) 2008 Marc-Andre Cournoyer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#   
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------
require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))
require 'snipe/daemonizable'

class TestServer
  include Snipe::Daemonizable
  
  def name
    'Snipe server'
  end
end

describe 'Daemonizable' do
  before :all do
    @pid_file = Snipe::Paths.pid_path( 'test.pid' )
    File.delete(@pid_file) if File.exist?(@pid_file)
  end
  
  before :each do
    FileUtils.mkdir_p Snipe::Paths.pid_path
    @server = TestServer.new
    @server.pid_file = @pid_file
    @pid = nil
  end

  after( :each ) do
    unless @child 
      FileUtils.rm_f File.join( Snipe::Paths.pid_path, "*.pid" )
      if File.exist?( Snipe::Paths.log_path( "snipe.log" ) ) then
        puts IO.read( Snipe::Paths.log_path( "snipe.log") )
        File.delete( Snipe::Paths.log_path( "snipe.log" ) )
      end
    end
  end
  
  it 'should have a pid file' do
    @server.should respond_to(:pid_file)
    @server.should respond_to(:pid_file=)
  end

  %w[ kill send_signal force_kill ].each do |class_method|
    it "should respond to the class method #{class_method}" do
      TestServer.should respond_to( class_method )
    end
  end
  
  it 'should create a pid file' do
    @pid = fork do
      @server.daemonize
      @child = true
      sleep 1
      exit 0
    end
 
    sleep 0.25
    Process.wait(@pid)
    File.exist?( @server.pid_file ).should be_true
    @pid = @server.pid

    lambda do
      sleep 0.1 while File.exist?( @server.pid_file ) 
    end.should take_less_than( 5 )
  end
  
  it 'should kill process in pid file' do
    @pid = fork do
      @server.daemonize
      @child = true
      loop { sleep 3 }
    end
  
    server_should_start_in_less_than 3
    
    @pid = @server.pid

    Process.should be_running( @pid )
    File.exist?(@server.pid_file).should be_true

    TestServer.kill(@server.pid_file, 2)
  
    File.exist?(@server.pid_file).should be_false
  end
  
  it 'should force kill process in pid file' do
    @pid = fork do
      @server.daemonize
      @child = true
      loop { sleep 0.3 }
    end
  
    server_should_start_in_less_than 1
    
    @pid = @server.pid
  
    File.exist?(@server.pid_file).should be_true
    TestServer.kill(@server.pid_file, 0)
  
    File.exist?(@server.pid_file).should be_false
  end
  
  it 'should send kill signal if timeout' do
    @pid = fork do
      @server.daemonize
      @child = true
      sleep 5
    end
  
    server_should_start_in_less_than 10
    
    @pid = @server.pid
  
    File.exist?(@server.pid_file).should be_true
    TestServer.kill(@server.pid_file, 1)
    
    sleep 1
  
    File.exist?(@server.pid_file).should be_false
    Process.running?(@pid).should be_false
  end
  
  it "should exit and raise if pid file already exist" do
    @pid = fork do
      @server.daemonize
      @child = true
      sleep 5
    end
    server_should_start_in_less_than 10
    
    @pid = @server.pid

    proc { @server.daemonize }.should raise_error(Snipe::Daemonizable::PidFileExist)
    
    File.exist?(@server.pid_file).should be_true
  end
  
  it "should should delete pid file if stale" do
    # Create a file w/ a PID that does not exist
    File.open(@server.pid_file, 'w') { |f| f << 999999999 }
    File.exist?( @server.pid_file ).should be_true
    
    @server.send(:remove_stale_pid_file)
    
    File.exist?(@server.pid_file).should be_false
  end
  
  after do
    Process.kill(9, @pid.to_i) if @pid && Process.running?(@pid.to_i)
    Process.kill(9, @server.pid) if @server.pid && Process.running?(@server.pid)
    File.delete(@server.pid_file) rescue nil
  end
  
  private
    def server_should_start_in_less_than(sec = 5)
      lambda do 
        loop do 
          sleep 0.1
          break if File.exist?( @server.pid_file )
        end
      end.should take_less_than( sec )
    end
end
