require 'tokyotyrant'

module Snipe
  class Database
    # handles for the standard databases
    def self.tweet_db
      unless @tweet_db 
        cfg = Configuration.for( 'database' ).tweet 
        @tweet_db = TokyoTyrant::RDBTBL.new
        if not @tweet_db.open( cfg.host, cfg.port ) then
          raise "Unable to connect to database at #{cfg.host}:#{cfg.port}"
          @tweet_db = nil
        end
      end
      return @tweet_db
    end
  end
end
