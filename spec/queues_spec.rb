require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))

require 'snipe/queues'

describe Snipe::Queues do
  %w[ gnip_activity_queue gnip_parse_queue ].each do |q| 
    it "logs an error if unable to connect to the #{q}" do
      qi = Snipe::Queues.send( q )
      qi.should be_nil
      spec_log.should =~ /Failure connecting to .* on tube .*/
    end
  end
end
