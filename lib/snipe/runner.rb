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

    def setup_signal_handling
      %w( INT QUIT TERM ).each do |s| 
        Signal.trap(s) do 
          logger.warn "Signal caught, stopping"
          exit 1
        end
      end
    end

    def run( command_name )
      logger.info "Running command #{command_name}"
      Snipe::Log.console = :info
      @options.each do |k,v|
        logger.debug "  #{k} => #{v}" if v
      end
      begin
        cmd  = Command.find( command_name ).new( @options )
        cmd.daemonize
        setup_signal_handling
        cmd.before
        cmd.run
      rescue => e
        logger.error "while running #{command_name} : #{e.message}"
        e.backtrace.each do |l|
          logger.debug l
        end
      ensure
        cmd.after
      end
      logger.info "end of command #{command_name}"
    end
  end
end
