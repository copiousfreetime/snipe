require 'curb'
require 'snipe/couchdb/tweet'
require 'nokogiri'
require 'hitimes'

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

    def initialize
      @curl = Curl::Easy.new do |c|
        c.headers = TweetFetcher.headers
        #c.verbose = true
      end
      @timer = ::Hitimes::Timer.new
      @xml_ok = true
    end

    def logger
      Logging::Logger[self]
    end

    def xml_ok?
      @xml_ok
    end

    def unzip( data )
      sio = StringIO.new( data )
      Zlib::GzipReader.new( sio ).read
    end

    def fetch_str_from_url( url )
      curl.url = url
      curl.perform
      if curl.response_code != 200 then
        logger.error unzip( curl.body_str )
        raise "Error : #{curl.response_code}"
      end
      unzip( curl.body_str )
    end

    # convert the url to the url that is needed for getting the html page
    # instead of the xml
    def html_url_for( tweet )
      num = File.basename( tweet.url, ".*" )
      return "http://twitter.com/#{tweet.actor}/status/#{num}"
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
          raise e
        end
      end

      timer.stop
      if timer.count % 100 == 0 then
        logger.info timer.stats.to_hash.inspect
      end
      return t
    end

    def fetch_text_from_xml( tweet )
      s = fetch_str_from_url( tweet.url )
      n = Nokogiri::XML( s )
      t = n.xpath("//text").text
    end
  end
end
