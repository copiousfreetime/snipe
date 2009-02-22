$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'

q = Snipe::Beanstalk::Queue.activity_queue
#q = Snipe::Beanstalk::Queue.parse_queue

puts "Listening for events on #{q.name}"
loop do
  job = q.reserve
  obj = nil 
  begin 
    obj = Marshal.restore( job.body )
  rescue => e
    obj = job.body
  end
  puts obj.inspect
  job.delete
end
