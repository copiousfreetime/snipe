require 'snipe'
require 'snipe/daemonizable'

module Snipe
  # The Command is the base class for any class that wants to implement a
  # commandline command for sst-agent.
  #
  # Inheriting from this class will make the class registered and be available
  # for invokation from the Runner class.
  #
  # The child must implemente the run method with no parameters, this will be
  # invoked by the runner.
  #
  # The lifecycle of a command is:
  #
  #   1) instantiation with a hash parameter
  #   2) before
  #   3) run
  #   4) after
  #   5) error called if the runner catches an exception from the command
  #
  class Command
    class Error < ::Snipe::Error; end

    include Daemonizable

    def self.command_name
      name.split("::").last.downcase
    end

    attr_reader :options
    def initialize( opts = {} )
      @options = opts
      n = options['instance-num'] 
      pid_parts = [ command_name ]
      pid_parts << options['instance-num'] if options['instance-num']
      pid_parts << "pid"
      @pid_file = Snipe::Paths.pid_path( pid_parts.join('.') )
    end

    def command_name
      self.class.command_name
    end

    def logger
      ::Logging::Logger[self]
    end

    # called by the Runner before the command, this can be used to setup
    # additional items for the command
    def before() nil end

    # called by the Runner to execute the command
    def run
      raise Error, "Unknown command `#{command_name}`"
    end

    # called by the Runner after run() has completed.  This will be called even
    # if an error happens during run
    def after() nil; end

    # called by the Runner if an error is encountered during the run method
    def error() nil; end

    # called by runner if a signal is hit
    def shutdown() nil; end

    class << self
      # this method is invoked by the Ruby interpreter whenever a class inherts
      # from Command.  This is how commands register to be invoked
      #
      def inherited( klass )
        return unless klass.instance_of? Class
        return if commands.include? klass
        commands << klass
      end

      # The list of commands registered.
      #
      def commands
        unless defined? @commands
          @commands = []
        end
        return @commands
      end

      # get the command klass for the given name
      def find( name )
        @commands.find { |klass| klass.command_name == name }
      end

    end
  end
end

require 'snipe/commands/setup'
require 'snipe/commands/consume'
require 'snipe/commands/split'
require 'snipe/commands/scrape'
#require 'snipe/commands/publish'
