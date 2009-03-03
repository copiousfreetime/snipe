require 'main'

require 'snipe/runner'
module Snipe
  Cli = Main.create {
    author  "Copyright 2009 (c) Jeremy Hinegardner"
    version ::Snipe::VERSION

    description <<-txt
    The command line tool for the snipe system.

    Run 'snipe help modename' for more information
    txt

    run { help! }

    mode( :setup ) {
      option( :home ) do
        description "The root directory of the Snipe process"
        argument :required
        default Snipe::Paths.root_dir
      end
 
      run { Cli.run_command_with_params( 'setup', params ) }
    }

    mode( :status ) {
      description <<-txt
      Report the status of the system.
      txt

      mixin :option_home
      mixin :option_log_level

      run { Cli.run_command_with_params( 'status', params ) }
    }

    mode( :consume ) {
      description <<-txt
      Consume the notification stream from Gnip and publish this event 
      to the split queue.
      txt

      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit
      mixin :option_stop

      run { Cli.run_command_with_params( 'consume', params ) }
    }

    mode( :split ) {
      description <<-txt
      Split the notification stream downloaded by 'consume' into 
      into individual activity events.
      txt
      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit
      mixin :option_stop
      mixin :option_servers

      run { Cli.run_command_with_params( 'split', params ) }
    }

    mode( :scrape ) {
      description <<-txt
      Scrape the activity events and push the resulting data 
      to the publish queue.
      txt
      
      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_servers
      mixin :option_stop
      mixin :option_limit

      run { Cli.run_command_with_params( 'scrape', params ) }
    }

    mode( :publish ) {
      description <<-txt
      Publish the fully inflated activity events to Gnip
      txt

      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit
      mixin :option_stop

      option( 'batch-size' ) do
        description "The number of activity events to bundle into one batch"
        argument :required
        cast :int
        default 1
      end
 
      run { Cli.run_command_with_params( 'publish', params ) }

    }

    mode( :store ) {
      description <<-txt
      Consume the activity events and store the resulting data into couchdb

      [ Currently not used ]
      txt

      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit
      mixin :option_stop
      mixin :option_servers

      run { Cli.run_command_with_params( 'store', params ) }
    }

    mode( :version ) {
      description "Output the version of the program"
      run { puts "#{self.name} version #{::Snipe::VERSION}" }
    }

    mixin :option_home do
      option( :home ) do
        description "The root directory of the Snipe process"
        argument :required
        validate { |v| ::File.directory?( v ) }
        default Snipe::Paths.root_dir
      end
    end

    mixin :option_servers do
      option( :servers ) do
        description "The number of copies of this server to run.  Using this option forces --daemonize for each process"
        argument :required
        validate { |v| Float( v ).to_i > 0 }
        cast :int
      end
    end

    mixin :option_stop do
      option( :stop ) do
        description "Stop all known instances of this server"
      end
    end

    mixin :option_daemonize do
      option( 'daemonize' ) do
        description "Daemonize the process"
        cast :boolean
      end
    end

    mixin :option_log_level do
      option( 'log-level' ) do
        description "The verbosity of logging, one of [ #{::Logging::LNAMES.map {|l| l.downcase }.join(', ')} ]"
        argument :required
        validate { |l| %w[ debug info warn error fatal off ].include?( l.downcase ) }
      end
    end

    mixin :option_limit do
      option( 'limit' ) do
        description "Only do N operations"
        argument :required
        validate { |l| Float(l).to_i }
        cast :int
      end
    end
  }

  #
  # Convert the Parameters::List that exists as the parameters from Main
  #
  def Cli.params_to_hash( params )
    (hash = params.to_hash ).keys.each { |key| hash[key] = hash[key].value }
    return hash
  end

  def Cli.run_command_with_params( command, params )
    ::Snipe::Runner.new( Cli.params_to_hash( params ) ).run( command )
  end

end
