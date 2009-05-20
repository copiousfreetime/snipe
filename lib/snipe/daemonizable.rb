require 'snipe/daemonize'

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

module Process
  # Returnsinfo +true+ the process identied by +pid+ is running.
  def self.running?(pid)
    Process.getpgid(pid) != -1
  rescue Errno::ESRCH
    false
  end
end


module Snipe
  module Daemonizable

    # Raised when the pid file already exist starting as a daemon.
    class PidFileExist < RuntimeError; end

    attr_accessor :pid_file

    def self.included( base )
      base.extend ClassMethods
    end

    def self.logger
        @logger ||= Logging::Logger[self]
    end

    def pid
      File.exist?(pid_file) ? open(pid_file).read.to_i : nil
    end
    
    # Turns the current script into a daemon process that detaches from the console.
    def daemonize
      raise ArgumentError, 'You must specify a pid_file to daemonize' unless @pid_file

      remove_stale_pid_file
     
      pwd = Dir.pwd # Current directory is changed during daemonization, so store it
         
      Daemonize.daemonize
      
      Dir.chdir(pwd)
        
      # reopen all the logs
      Snipe::Log.init
      write_pid_file

      Daemonizable.logger.info "Running as a daemon, pid file -> #{pid_file}"

      at_exit do
        Daemonizable.logger.info "Exiting!"
        remove_pid_file
      end
    end  

    module ClassMethods
      # Send a QUIT or INT (if timeout is +0+) signal the process which
      # PID is stored in +pid_file+.
      # If the process is still running after +timeout+, KILL signal is
      # sent.
      def kill(pid_file, timeout=60)
        if timeout == 0
          send_signal('INT', pid_file, timeout)
        else
          send_signal('QUIT', pid_file, timeout)
        end
      end 


      # Send a +signal+ to the process which PID is stored in +pid_file+.
      def send_signal(signal, pid_file, timeout=60)
        if File.file?(pid_file) && pid = File.read(pid_file)
          pid = pid.to_i
          Daemonizable.logger.info "Sending #{signal} signal to process #{pid} ... "
          Process.kill(signal, pid)
          Timeout.timeout(timeout) do
            sleep 0.1 while Process.running?(pid)
          end
        else
          $stderr.puts "Can't stop process, no PID found in #{pid_file}"
        end
      rescue Timeout::Error
        Daemonizable.logger.error "Timeout sending signal to process #{pid}"
        force_kill pid_file
      rescue Interrupt
        force_kill pid_file
      rescue Errno::ESRCH # No such process
        Daemonizable.logger.error "process #{pid} not found not found!"
        force_kill pid_file
      end

      def force_kill(pid_file)
        pid = File.read( pid_file ).strip
        Daemonizable.logger.warn "Doing a force kill on #{pid}"
        Process.kill("KILL", pid ) rescue nil
        if File.exist?( pid_file ) then
          Daemonizable.logger.warn "Removing pid file #{pid_file}"
          File.delete( pid_file ) rescue nil
        end
      end
    end

  protected
    def remove_pid_file
      if @pid_file && File.exist?( @pid_file ) then
        Daemonizable.logger.info "Deleting PID file #{@pid_file}"
        File.delete(@pid_file) 
      end
    end

    def write_pid_file
      Daemonizable.logger.info "Writing PID to #{@pid_file}"
      FileUtils.mkdir_p File.dirname( @pid_file )
      open( @pid_file,"w" ) { |f| f.write( Process.pid ) }
      File.chmod( 0644, @pid_file )
    end

    # If PID file is stale, remove it.
    def remove_stale_pid_file
      if File.exist?(@pid_file)
        if pid && Process.running?(pid)
          raise Daemonizable::PidFileExist, 
                "#{@pid_file} already exists, seems like it's already running (process ID: #{pid}). " +
                "Stop the process or delete #{@pid_file}."
        else
          Daemonizable.logger.info "Deleting stale PID file #{@pid_file}"
          remove_pid_file
        end
      end
    end
  end
end
