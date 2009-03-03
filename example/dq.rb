require 'rubygems'
require 'beanstalk-client'

q = ::Beanstalk::Connection.new( "localhost:11300", "publish" )

count = 0
loop do
  stats = q.stats_tube( "publish" )
  current_size    = stats['current-jobs-ready'] || 0

  break unless current_size > 0

  job = q.reserve
  count += 1
  obj = nil 
  begin 
    obj = Marshal.restore( job.body )
  rescue => e
    obj = job.body
  end
  job.delete
  print "#{count}\r"
end
puts "Drained #{count} jobs"
