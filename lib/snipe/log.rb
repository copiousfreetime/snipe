require 'logging'
require 'snipe'

module Snipe
  ::Logging::Logger[self].level = :info
  def self.logger
    ::Logging::Logger[self]
  end

  module Log

    # Initialize the top level logger.  This should not be done until after
    # the global configuration is parsed and loaded
    def self.init

      if defined? @initialized and ( not @appender.nil? ) then
        Snipe.logger.remove_appenders( @appender )
        @appender.close
        @appender = nil
      end

      FileUtils.mkdir_p( directory ) unless File.directory?( directory )
      Snipe.logger.add_appenders( self.appender )
      Snipe.logger.info "Snipe version #{Snipe::VERSION}"
      self.level = configuration.level

      @initialized = true
    end

    def self.configuration
      @configuration ||= ::Configuration.for("logging")
    end

    def self.level
      ::Logging::Logger[Snipe].level
    end

    def self.level=( l )
      ::Logging::Logger[Snipe].level = l
      self.appender.level = l
    end

    def self.default_directory
      configuration.dirname || ::Snipe::Paths.log_path 
    end

    def self.directory
      @directory ||= default_directory 
      if @directory != default_directory then
        # directory has changed on us 
        @directory = default_directory 
      end
      return @directory
    end

    def self.filename
      File.join( self.directory, ( configuration.filename || "sst-agent.log" ) )
    end

    def self.layout
      @layout ||= Logging::Layouts::Pattern.new(
        :pattern      => "[%d] %5l %6p %c : %m\n",
        :date_pattern => "%Y-%m-%d %H:%M:%S"
      )
    end

    def self.appender
      @appender ||= ::Logging::Appenders::RollingFile.new(
          'snipe',
          :filename => self.filename,
          :layout   => self.layout,
          :size     => 1024**2 * 25 # 25 MB
      )
    end
  end
end
