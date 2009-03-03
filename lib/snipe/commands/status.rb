module Snipe::Commands
  class Status < Snipe::Command
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

    def log_queue_status
      Snipe::Beanstalk::Queue.list.each do |q|
        s = q.stats 
        logger.info "#{s['name'].center( 7 )} -> #{s['current-jobs-ready']} waiting jobs #{s['current-jobs-reserved']} out for processing #{s['current-waiting']} clients waiting for jobs"
      end
    end

    def run

      log_system_status
      log_queue_status

    end
  end
end
