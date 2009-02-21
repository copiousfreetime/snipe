require 'beanstalk-client'
module Snipe
  module Queues
    GnipEventQueue = ::Beanstalk::Connection.new( Configuration.for('gnip').queue.connection, 
                                                  Configuration.for('gnip').queue.name  )
  end
end
