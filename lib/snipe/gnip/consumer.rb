require 'base64'
require 'curb'
require 'zlib'
require 'time'
require 'parsedate'
require 'hitimes'
require 'observer'

class Time
  def self.from_bucket_id( id )
    year  = id[0..3].to_i
    month = id[4..5].to_i
    day   = id[6..7].to_i
    hour  = id[8..9].to_i
    min   = id[10..11].to_i
    Time.gm( year, month, day, hour, min, 0, 0 )
  end

  def to_bucket_id
    strftime("%Y%m%d%H%M")
  end
end

module Snipe
  module Gnip
    class Consumer
      def self.base_url
        @base_url ||= Configuration.for('gnip').notification_url
      end

      def self.start_bucket
        "200810010401"
      end

      attr_reader :username
      attr_reader :password
      attr_reader :user_agent

      attr_accessor :limit
      attr_reader   :count

      include Observable

      # initialize with the username and password of the person connecting 
      def initialize( config = Configuration.for('gnip') )
        @username = config.connection.username
        @password = config.connection.password
        @user_agent = config.user_agent
        @compressed = config.compressed
        @headers = nil
        @start_bucket = nil
        @limit = nil
        @count = 0
      end  

      # is the data stream compressed
      def compressed?
        @compressed
      end

      def logger
        Logging::Logger[self]
      end

      # the first bucket to retrieve from gnip
      def start_bucket
        unless @start_bucket
          if File.exist?( last_bucket_id_file ) then
            @start_bucket = get_last_bucket_id
          else
            @start_bucket = Consumer.start_bucket
          end
        end
        logger.info "Start bucket is #{@start_bucket}"
        return @start_bucket
      end

      def last_bucket_id_file
        Snipe::Paths.data_path( "last_bucket_id.txt" )
      end

      def get_last_bucket_id
        IO.read( last_bucket_id_file ).strip
      end

      def update_last_bucket_id( bucket_id )
        @count += 1
        File.open( last_bucket_id_file, "wb" ) { |f| f.puts "#{bucket_id}" }
      end

      def bucket_url( bucket_id )
        File.join( Consumer.base_url, "#{bucket_id}.xml" )
      end


      # the headers to send to to gnip
      def headers
        unless @headers 
          @headers = {
            'Authorization'    => "Basic #{Base64::encode64( "#{username}:#{password}" )}".strip,
            "Content-Type"     => "application/xml",
            "User-Agent"       => user_agent
          }
          if compressed? then
            @headers['Content-Encoding'] = "gzip"
            @headers['Accept-Encoding'] = "gzip"
          end
        end
        return @headers
      end

      def gnip_last_bucket_id
        c = ::Curl::Easy.new( "https://prod.gnipcentral.com/" )
        c.headers = self.headers
        bucket_id = 0
        c.on_header do |data| 
          length = data.length
          md = data.strip.match(/^Date: (.*)$/)
          if md then
            date = md.captures[0]
            t = Time.parse( date ).utc
            bucket_id = (t - 60).to_bucket_id
          end
          data.length
        end
        c.perform
        return bucket_id
      end

      def bucket_data_file( bucket_id )
        t = Time.from_bucket_id( bucket_id )
        d = Snipe::Paths.data_path( t.strftime( "%Y/%m/%d" ) )
        FileUtils.mkdir_p( d ) unless File.directory?( d )
        File.join( d, "#{bucket_id}.xml.gz" )
      end
      
      def unzip( data )
        sio = StringIO.new( data )
        ::Zlib::GzipReader.new( sio ).read
      end



      # given a bucket id download it from gnip and put it in the appropriate file  
      def download_bucket( bucket_id )
        url = bucket_url( bucket_id )
        c = Curl::Easy.new( url )
        c.headers = self.headers
        #c.verbose = true
        c.perform
        if c.response_code != 200 then
          logger.error unzip( c.body_str )
          raise "Error : #{c.response_code}"
        end
        bucket = bucket_data_file( bucket_id )
        File.open( bucket, "wb" ) do |f|
          f.write( c.body_str )
          logger.info "writing #{bucket}"
        end
        return bucket
      end

      def next_bucket_id( this_bucket )
        t = Time.from_bucket_id( this_bucket )
        (t + 60).to_bucket_id
      end

      def download_batch(first, last)
        logger.info "Downloading #{first} -> #{last}"
        current = first
        timer = Hitimes::Timer.new
        while current <= last
          timer.measure do 
            bucket_file = download_bucket( current )
            update_last_bucket_id( current )
            current = next_bucket_id( current )

            self.changed
            self.notify_observers( bucket_file )
          end
          break if limit_reached?
        end
        return timer
      end       

      def limit_reached?
        if self.limit and ( self.count >= self.limit ) then
          return true
        end
        return false
      end

      def start
        current_bucket_id = self.start_bucket
        current_max_bucket_id = self.gnip_last_bucket_id
        logger.info "Gnip download service started"
        if limit then
          logger.info "  limiting to #{self.limit} downloads"
        end
        loop do 
          break if limit_reached?
          timer = download_batch(current_bucket_id, current_max_bucket_id)
          logger.info "Batch of #{timer.count} downloaded at #{timer.rate} bps"
          current_bucket_id = next_bucket_id( current_max_bucket_id )
          loop do
            current_max_bucket_id = self.gnip_last_bucket_id
            break if (current_max_bucket_id >= current_bucket_id) or limit_reached?
            sleep 60
          end
        end
      end
    end
  end
end
