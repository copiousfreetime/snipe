require 'snipe/command'
require 'snipe/configuration'
require 'snipe/log'

module Snipe
  # Prepares the environment and then runs a command.  This makes sure that the
  # configuration file is loaded and the logger is writing and then runs the
  # given command
  class Runner
    attr_reader :options

    def initialize( opts = {} )
      @options = opts.dup
      load_configuration
      initialize_logging
    end

    def snipe_config
      ::Configuration.for('snipe')
    end

    def load_configuration
      if options['home'] then
        config_path = ::File.expand_path( File.join( options['home'], 'config' ) )
        ::Configuration.path = config_path
        if File.exist?( File.join( config_path, 'snipe.rb' ) ) then 
          ::Configuration.load 'snipe'
        end

        # TODO : talk to ara about how to do this better
        ::Configuration.for('snipe', 'home' => options['home'] )

        Paths.home_dir = snipe_config.home
      end
    end

    def initialize_logging
      if options['log-level'] then
        ::Configuration.for('logging', 'level' => options['log-level'] )
      end

      Snipe::Log.init
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    def setup_signal_handling( cmd )
      %w( INT QUIT TERM ).each do |s| 
        Signal.trap(s) do 
          cmd.shutdown
          logger.warn "Signal caught, stopping"
          exit 1
        end
      end
    end

    # Spawn self as a number of sub processes by iterating over the
    # number of children
    def spawn( command_name, count )
      count.times do |instance_num|
        if cpid = fork then
          Process.detach( cpid )
          logger.info "Spawned child number #{instance_num}"
        else
          options['daemonize'] = true
          options['instance-num'] = instance_num
          command_lifecycle( command_name )
          break
        end
      end
    end

    # stop all running instances of the command
    def stop( command_name )
      pidfiles = Dir.glob( Snipe::Paths.pid_path( "#{command_name}*.pid" ) )
      if pidfiles.empty? then
        logger.info "Doesn't look like there are any #{command_name} pid files."
        logger.info "Make sure to pass the --home option if you need too. "
        logger.info "Pid files are in the 'pid' directory below home"
        logger.info "Try 'snipe status'"
        return nil
      end

      pidfiles.each do |pidfile|
        pid = Float( File.read( pidfile ) ).to_i
        logger.info "Telling #{pid} to stop ..."
        Command.kill( pidfile )
        while Process.running?( pid ) do
          logger.info "Waiting for #{pid} to stop ..."
          sleep 1
        end
      end
    end

    def run( command_name )
      Snipe::Log.console = :info

      if options['stop'] then
        stop( command_name )
      elsif options['servers'] then
        spawn( command_name, options['servers'] )
      else
        command_lifecycle( command_name )
      end
    end

    def command_lifecycle( command_name )
      logger.info "Running command #{command_name}"
      @options.each do |k,v|
        logger.debug "  #{k} => #{v}" if v
      end

      cmd  = Command.find( command_name ).new( @options )
      begin
        if options['daemonize'] then
          cmd.daemonize
          logger.debug "current programname = [$0]"
          $0 = "snipe #{command_name} home #{options['home']} pidfile #{cmd.pid_file}"
        end
        setup_signal_handling( cmd )
        cmd.before
        cmd.run
      rescue => e
        logger.error "while running #{command_name} : #{e.message} (check logs for backtrace)"
        e.backtrace.each do |l|
          logger.warn l
        end
      ensure
        cmd.after
      end
      logger.info "end of command #{command_name}"
    end
  end
end
