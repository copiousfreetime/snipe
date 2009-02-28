#!/usr/bin/env ruby
require 'rubygems'
require 'beanstalk-client'

conn = ::Beanstalk::Connection.new( "localhost:11300" )


tubes = conn.list_tubes.sort
samples    = 10
sleep_time = 5
differences = Hash.new( 0 )
prev_size   = Hash.new( 0 )
tubes.each { |t| 
  differences[t] = [] 
  s = conn.stats_tube( t )
  if s then
    prev_size[t] = s['current-jobs-reader']
  else
    prev_size[t] = 0
  end
}

loop do
  sleep sleep_time
  puts "-<>-" * 20

  conn.list_tubes.sort.each do |tube|

    stats           = conn.stats_tube( tube )
    next if not stats

    current_size    = stats['current-jobs-ready'] || 0
    t_prev_size     = prev_size[tube] || 0
    prev_size[tube] = current_size
    t_diff          = differences[tube]

    diff            = t_prev_size - current_size 
    t_diff.push diff
    t_diff.shift if t_diff.size > samples

    sum             = t_diff.inject(0) { |sum, n| sum + n }
    sample_seconds  = Float( sleep_time * t_diff.size )
    drain_rate      = sum / Float( sleep_time * t_diff.size ) # jobs / sec
    worker_count    = stats['current-jobs-reserved']

    if current_size > 0 && drain_rate > 0 then
      estimated_seconds = current_size / drain_rate
      completed_at = Time.now + estimated_seconds

      puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} (#{tube.center(15)}) : #{current_size} jobs left draining at #{"%0.2f"% drain_rate} jobs/sec by #{worker_count} workers, estimated completion at #{completed_at.strftime("%Y-%m-%d %H:%M:%S")}"
    else
      puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} (#{tube.center(15)}) : #{current_size} jobs with #{worker_count} workers waiting."
    end
  end
end
