require 'rubygems'
require 'spec'

$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'

Logging::Logger['Snipe'].level = :all
module Spec
  module Log
    def self.io
      @io ||= StringIO.new
    end
    def self.appender
      @appender ||= Logging::Appenders::IO.new( "speclog", io )
    end

    Logging::Logger['Snipe'].add_appenders( Log.appender )

    def self.layout
      @layout ||= Logging::Layouts::Pattern.new(
        :pattern      => "[%d] %5l %6p %c : %m\n",
        :date_pattern => "%Y-%m-%d %H:%M:%S"
      )
    end

    Log.appender.layout = layout

  end

  module Helpers
    require 'tmpdir'
    def make_temp_dir( unique_id = $$ )
      dirname = File.join( Dir.tmpdir, "snipe-#{unique_id}" ) 
      FileUtils.mkdir_p( dirname ) unless File.directory?( dirname )
      return dirname
    end

    # the logging output from the test, if that class has any logging
    def spec_log
      Log.io.string
    end
  end

  # take_less_than matcher from Thin
  module Matchers
    class TakeLessThan
      def initialize(time)
        @time = time
      end

      def matches?(proc)
        Timeout.timeout(@time) { proc.call }
        true
      rescue Timeout::Error
        false 
      end

      def failure_message(negation=nil)
    "should#{negation} take less then #{@time} sec to run"
      end

      def negative_failure_message
        failure_message ' not'
      end
    end

    def take_less_than(time)
      TakeLessThan.new(time)
    end 
  end
end

Spec::Runner.configure do |config|
  config.include Spec::Helpers
  config.include Spec::Matchers

  config.before do
    Spec::Log.io.rewind
    Spec::Log.io.truncate( 0 )
  end

  config.after do
    Spec::Log.io.rewind
    Spec::Log.io.truncate( 0 )
  end
end  

