require 'fileutils'
module Snipe::Commands
  class Setup < Snipe::Command
    def run
      home = File.expand_path( options['home'] )
      unless File.directory?( home )
        logger.info "Creating home directory #{home}"
        FileUtils.mkdir_p home
      end
      
      %w[ pid config data log tmp ].each do |sub|
        meth = "#{sub}_path"
        d = Snipe::Paths.send( meth )
        unless File.directory?( d )
          logger.info "Creating #{sub} directory : #{d}"
          FileUtils.mkdir_p d
        end
      end

      cfg_file = Snipe::Paths.config_path( "snipe.rb" )
      unless File.exist?( cfg_file )
        File.open( cfg_file, "wb" ) do |f|
          f.write IO.read( Snipe::Paths.lib_path( "snipe", "configuration.rb" ) )
        end
      end
      puts "#{home} now setup as a home directory for sniping."
    end
  end
end
