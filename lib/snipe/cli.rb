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
      mixin :option_home
      mixin :option_log_level
    }

    mode( :scrape ) {
      mixin :option_home
      mixin :option_log_level
      mixin :option_daemonize

      run { Cli.run_command_with_params( 'scrape', params ) }
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
        argument :none
        default :false
      end
    end

    mixin :option_log_level do
      option( 'log-level' ) do
        description "The verbosity of logging, one of [ #{::Logging::LNAMES.map {|l| l.downcase }.join(', ')} ]"
        argument :required
        validate { |l| %w[ debug info warn error fatal off ].include?( l.downcase ) }
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
