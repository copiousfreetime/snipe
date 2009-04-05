require 'curb'
require 'snipe/tweet'
require 'nokogiri'
require 'hitimes'
require 'zlib'

module Snipe
  class TweetFetcher
    def self.user_agent
        "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.6) Gecko/2009011912 Firefox/3.0.6"
    end

    def self.headers
      { "User-Agent" => user_agent,
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip" }
    end

    attr_reader :curl
    attr_reader :timer
    attr_reader :response_code_counts

    def initialize
      @curl = Curl::Easy.new do |c|
        c.headers = TweetFetcher.headers
        #c.verbose = true
      end
      @timer = ::Hitimes::Timer.new
      @xml_ok = false
      @response_code_counts = Hash.new( 0 )
    end

    def logger
      Logging::Logger[self]
    end

    def xml_ok?
      @xml_ok
    end

    def unzip( data )
      sio = StringIO.new( data )
      ::Zlib::GzipReader.new( sio ).read
    end

    def fetch_str_from_url( url )
      curl.url = url
      curl.perform
      c = curl.response_code
      self.response_code_counts[c] = self.response_code_counts[c] + 1

      unless curl.body_str 
        if logger.debug? then
          logger.debug "#{url} -> no body #{curl.response_code}"
        end
        throw :skip_etch
      end

      body = unzip( curl.body_str )

      case c
      when 200
        body
      when 400
        raise "yup, exceeded limit"
      else
        if logger.debug? then
          logger.debug "#{url} -> recieved response code #{curl.response_code}"
        end
        throw :skip_fetch
      end
    end

    # convert the url to the url that is needed for getting the html page
    # instead of the xml
    def html_url_for( tweet )
      tweet.destinationurl
    end

    def fetch_text_from_html( tweet )
      s = fetch_str_from_url( html_url_for( tweet ) )
      n = Nokogiri::HTML( s )
      t = n.css('span.entry-content').text 
    end


    # Fetch a twitter message like the following
    #  http://twitter.com/statuses/show/1232707799.xml
    #
    def fetch_text( tweet )
      timer.start
      t = nil
      trys = 0
      begin
        if xml_ok? then
          t = fetch_text_from_xml( tweet )
        else
          t = fetch_text_from_html( tweet )
        end
      rescue => e
        if xml_ok? then
          logger.error "#{e}"
          @xml_ok = false
          retry
        else
          trys += 1
          if trys < 10 then
            logger.info "Retry number #{trys} : #{html_url_for( tweet )}"
            retry
          end
          logger.error "#{e}"
          e.backtrace.each do |l|
            logger.warn l.strip
          end
          raise e
        end
      end

      timer.stop
      log_stats
      return t
    end

    def log_stats( force = false )
      if force || (timer.count % 100 == 0) then
        logger.info "Fetched #{timer.count} tweets in #{"%0.3f"% timer.sum} second at #{"%0.3f" % timer.rate} tweets / second"
        logger.info "  code counts #{response_code_counts.keys.sort.collect { |k| "#{k} => #{response_code_counts[k.to_i]}" }.join("  ")}"
      end
    end

    def fetch_text_from_xml( tweet )
      s = fetch_str_from_url( tweet.url )
      n = Nokogiri::XML( s )
      t = n.xpath("//text").text
    end
  end
end
