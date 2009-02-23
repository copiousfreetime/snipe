#!/usr/bin/env ruby
require 'rubygems'
require 'beanstalk-client'

conn = ::Beanstalk::Connection.new( "localhost:11300" )

tube = 'gnip-activity'

samples = 30
sleep_time = 1
differences = []

stats = conn.stats_tube( tube )
prev_size = stats['current-jobs-ready']


loop do
  sleep sleep_time
  stats = conn.stats_tube( tube )

  current_size = stats['current-jobs-ready']
  diff = prev_size - current_size 
  differences.push diff
  prev_size = current_size

  differences.shift if differences.size > samples

  sum = differences.inject(0) { |sum, n| sum + n }
  drain_rate = sum / Float( sleep_time * differences.size ) # jobs / sec
  estimated_seconds = current_size / drain_rate
  worker_count = stats['current-jobs-reserved']
  completed_at = Time.now + estimated_seconds
  puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} (#{tube}) : #{current_size} jobs left draining at #{"%0.2f"% drain_rate} jobs/sec by #{worker_count} workers, estimated completion at #{completed_at.strftime("%Y-%m-%d %H:%M:%S")}"
end
