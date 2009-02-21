require File.expand_path( File.join( File.dirname( __FILE__ ),"spec_helper.rb"))

require 'snipe/runner'

describe Snipe::Runner do
  before( :each ) do
    @home = make_temp_dir
  end

  after( :each ) do
    FileUtils.rm_rf( @home )
  end


  describe "initializing with a 'home' option" do
    before( :each ) do
      @runner = Snipe::Runner.new( 'home' => @home )
    end

    it "changes the Paths#home_dir" do
      Snipe::Paths.home_dir.should == @home
    end

    %w[ config data log tmp ].each do |d|
      check_path = "#{d}_path"
      it "affects the location of #{check_path}" do
        p = Snipe::Paths.send( check_path )
        p.should == ( File.join( @home, d ) + File::SEPARATOR )
      end
    end
  end

  it "loads an additional configuration file out of 'home'" do
    conf_dir = File.join( @home, "config" )
    FileUtils.mkdir_p( conf_dir )
    File.open( File.join( conf_dir, "snipe.rb" ), "wb+"  ) do |f|
      f.puts <<-cnf
      Configuration.for('scanner') do 
        skip_count 42
        foo 19
      end
      cnf
    end
    runner = Snipe::Runner.new( 'home' => @home )
    Snipe::Paths.config_path.should == File.join( @home, 'config' ) + File::SEPARATOR

    (Configuration.path.first + File::SEPARATOR).should == Snipe::Paths.config_path
    Configuration.for('scanner').skip_count.should == 42
    Configuration.for('scanner').foo.should == 19

  end

  it "can set the log level" do
    runner = Snipe::Runner.new( 'home' => @home,
                                     'log-level' => 'error' )
    runner.logger.debug "test at debug"
    runner.logger.info "test at info"
    runner.logger.error "test at error"

    File.directory?( ::Snipe::Log.directory ).should == true
    File.exist?( ::Snipe::Log.filename ).should == true
    lines = IO.readlines( Snipe::Log.filename )
    lines.size.should == 2

    lines.join('').should_not =~ /test at info/
    lines[1].should =~ /test at error/
  end
end
