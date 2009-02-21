$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'snipe'

q = Snipe::Queues.gnip_activity_queue
q.list_tubes.each do |t|
  stats = q.stats_tube( t )
  puts "Name : #{t}    total-jobs : #{stats['total-jobs']}    current-jobs-read : #{stats['current-jobs-ready']}"
end
puts "Listening for events on #{q.list_tube_used} #{q.list_tubes_watched}"
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
