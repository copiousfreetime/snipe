#-----------------------------------------------------------------------------
# Daemonize is http://grub.ath.cx/daemonize/ With alterations specific to
# snipe's workflow.
#-<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--
#
# [Copying]
# The Daemonize extension module is copywrited free software by Travis Whitton
# <whitton@atlantic.net>. You can redistribute it under the terms specified in
# the COPYING file of the Ruby distribution.
#-----------------------------------------------------------------------------

module Snipe

  module Daemonize

    def self.options
      @options ||= { 
        :close_file_descriptors => true, 
        :stdout                 => "/dev/null",
        :stderr                 => "/dev/null"
      }
    end

    # Try to fork if at all possible retrying every 5 sec if the
    # maximum process limit for the system has been reached
    def self.safefork
      tryagain = true

      while tryagain
        tryagain = false
        begin
          if pid = fork
            return pid
          end
        rescue Errno::EWOULDBLOCK
          sleep 5
          tryagain = true
        end
      end
    end


    # This method causes the current running process to become a daemon
    # If closefd is true, all existing file descriptors are closed
    def self.daemonize( opts = {} )
      opts = Daemonize.options.merge( opts )

      srand # Split rand streams between spawning and daemonized process
      safefork and exit # Fork and exit from the parent

      # Detach from the controlling terminal
      unless sess_id = Process.setsid
        raise 'Cannot detach from controlled terminal'
      end

      # Prevent the possibility of acquiring a controlling terminal
      trap 'SIGHUP', 'IGNORE'
      exit if pid = safefork

      Dir.chdir "/"   # Release old working directory
      File.umask 0000 # Insure sensible umask

      if opts[:close_file_descriptors] then
        # Make sure all file descriptors are closed
        ObjectSpace.each_object(IO) do |io|
          unless [STDIN, STDOUT, STDERR].include?(io)
            io.close rescue nil
          end
        end
      end

      STDIN.reopen "/dev/null"         # Free file descriptors and
      STDOUT.reopen opts[:stdout], "a" # point them somewhere sensible
      STDERR.reopen opts[:stderr]      # STDOUT/STDERR should go to a logfile
      return sess_id
    end
  end
end
