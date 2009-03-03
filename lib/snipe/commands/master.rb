module Snipe::Commands
  class Master < Snipe::Command
    def configuration
      @configuration ||= Configuration.for('snipe')
    end

    def run
      if options['shutdown'] || options['startup'] then
        on_off= options['shutdown'] ? "--stop" : ""
        daemons = configuration.daemons.order
        daemons.each do |d|
          servers = configuration.daemons.send( d )
          servopt = "--servers #{servers}"
          if servers == 1 then
            servopt = "--daemonize"
          end
          cmd = "#{Snipe::Paths.bin_path( 'snipe')} #{d} #{on_off} #{servopt} --home #{Snipe::Paths.home_dir}"
          logger.info "Running `#{cmd}`"
          x = %x[ #{cmd} ]
          x.split("\n").each { |l| logger.info l.strip }
        end
      else
        logger.error "You need the --start or the --stop option"
      end
    end
  end
end
