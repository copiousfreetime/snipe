module Snipe::Commands
  class Status< Snipe::Command
    def log_system_status
      logger.info "System Status".center( 42 )
      logger.info "-" * 42
      logger.info "  Snipe Home Directory : #{Snipe::Paths.home_dir}"
      logger.info ""
      logger.info "  Known processes      >"

      pidfiles = Dir.glob( Snipe::Paths.pid_path( "*.pid" ) )
      pidfiles.each do |pidfile|
        pid =  File.read( pidfile ) 
        alive = Process.running?( Float(pid).to_i )
        logger.info "  #{pid.ljust( 20 , ".")} #{alive ? "running" : "not running, clean this up"}"
      end
    end


    def run

      log_system_status

    end
  end
end
