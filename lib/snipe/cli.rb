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

    mode( :notify ) {
      description <<-txt
      Download the notification stream from Gnip.
      txt

      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit

      run { Cli.run_command_with_params( 'notify', params ) }
    }

    mode( :parse ) {
      description <<-txt
      Parse the notification stream downloaded by 'notify' and emit activity events.
      txt
      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit

      run { Cli.run_command_with_params( 'parse', params ) }
    }

    mode( :store ) {
      description <<-txt
      Consume the activity events and store the resulting data into couchdb
      txt

      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize
      mixin :option_limit

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
