require File.expand_path( File.join( File.dirname( __FILE__ ),"..", "spec_helper.rb"))

require 'snipe/beanstalk/queue'

describe Snipe::Beanstalk::Queue do
  %w[ split_queue scrape_queue publish_queue ].each do |q| 
    it "logs an error if unable to connect to the #{q}" do
      lambda { Snipe::Beanstalk::Queue.send( q ) }.should raise_error( StandardError, /Connection refused/) 
      spec_log.should =~ /Failure connecting to .*:\d+\/\w+/
    end
  end
end
