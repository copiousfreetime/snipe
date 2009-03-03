#-<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>-
# Master default configuration for snipe, this shows all the
# available options for each section.
#-<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>--<>-
require 'configuration'

#-----------------------------------------------------------------------
# Top level operation options
#-----------------------------------------------------------------------
Configuration.for('snipe') do
  # The top directory of the agents working location.  This is set with the
  # --directory commandline option, or it can be set here.
  home    nil

  # The temporary directory that is used by snipe for scratch space.
  # Generally this is the 'tmp' directory below home.
  tmp_dir  nil

  # the counts of number of daemons of each system that should be run
  # 'order' holds the startup and the shutdown order will be the reverse
  daemons {
    order   %w[ publish store scrape split consume ]
    consume 1
    split   2
    scrape  24
    store   2
    publish 1
  }
end

#-----------------------------------------------------------------------
# Program-wide logging configuration
#-----------------------------------------------------------------------
Configuration.for("logging" ) do
  # the default minimum logging level.
  # The leve should be one of : debug, info, warn, error, fatal
  level     "info"

  # the directory into which logs will be written, leaving this as nil will make
  # the default be used.  The default dirname is the 'log' directory below the
  # directory given in the --home option on the commandline.  If there is
  # no commandline --home option, then it is the 'log' directory directly
  # beneath the root directory of the snipe process directory.
  dirname   nil

  # The name of the log file itself in the dirname.  This is the name of the
  # current log that is being written to.  All the other logs will use this name
  # as the basename, and will have a number in the name.  The logs are number
  # from most recent after current(1) to the oldest number.
  filename "snipe.log"
end

#-----------------------------------------------------------------------
# Configuration for all the queues involved
#-----------------------------------------------------------------------
Configuration.for("queues") do
  # The connection string for the gnip beanstalk queue dealing with split events
  split {
    name       "split"
    connection "localhost:11300"
    error_limit 20
  }

  # The connection string for the gnip beanstalk queue dealing with scrape 
  # events
  #
  scrape {
    name       "scrape"
    connection "localhost:11300"
    error_limit 20
  }

  # The connection string for the gnip beanstalk queue dealing with store
  # events
  #
  store {
    name       "store"
    connection "localhost:11300"
    error_limit 20
  }


  # The connection information for the beanstalk queue for publish events
  #
  publish {
    name       "publish"
    connection "localhost:11300"
    error_limit 20
  }

end

#-----------------------------------------------------------------------
# Configuration for all things related to gnip
#-----------------------------------------------------------------------
Configuration.for('gnip') do
  # The consumer connection information
  connection {
    username "jeremy@copiousfreetime.org"
    password "red1fish"
  }

  user_agent        "Snipe/#{Snipe::Version}"
  compressed        true
  notification_url  "https://demo-v21.gnip.com/gnip/publishers/twitter/notification/"
  
end


#-----------------------------------------------------------------------
# Configuration for all things database
#-----------------------------------------------------------------------
Configuration.for("database") do
  tweet {
    host "127.0.0.1"
    port 1978
  }
end
