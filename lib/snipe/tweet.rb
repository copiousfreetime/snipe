require 'orderedhash'
require 'addressable/uri'
require 'time'
require 'snipe/julian'

module Snipe
  class Tweet

    # used to build up a tweet from parts
    class Fragment 
      attr_reader   :name
      attr_reader   :attributes
      attr_accessor :children

      def initialize( name, attributes = [] )
        @name       = name
        @attributes = attributes.empty? ? {} : Hash[ *attributes ]
        @children   = []
        @text       = []
      end

      def add_text( x )
        @text << x
      end

      def text
        @text.join('')
      end
    end

    def self.db_fields
      %w[ type status_id author text url destinationurl source at hashtags mentions urls 
          post_date post_at consume_at split_at scrape_at store_at publish_at author_snapshot_key ]
    end

    # initialize a tweet from a fragment this is typically done from a Gnip
    # Document
    attr_reader   :fragments
    attr_accessor :text
    attr_reader   :type
    attr_accessor :consume_at
    attr_accessor :split_at
    attr_accessor :scrape_at
    attr_accessor :store_at
    attr_accessor :publish_at

    def initialize( array = [] )
      @fragments = OrderedHash.new
      @text      = nil
      @type      = 'Tweet'

      # stamps for various things
      @consume_at = nil
      @split_at   = nil
      @scrape_at  = nil
      @store_at   = nil
      @publish_at = nil
      @post_date  = nil
      @post_at    = nil

      unless array.empty? 
        ohash = OrderedHash[ *array ]
        ohash.each_pair do |k,v|
          next if k == 'text'
          f = Fragment.new( k )
          f.add_text( v )
          add_fragment( f )
        end
        if ohash['text'] then
          @text = ohash['text']
        end
      end
    end

    def add_fragment( frag )
      case fragments[frag.name]
      when nil
        fragments[frag.name] = frag
      when Array
        fragments[frag.name] << frag
      else
        prev = fragments[frag.name]
        fragments[frag.name] = [ prev, frag ]
      end
    end

    
    def url
      fragments['url'].text
    end

    def at
      fragments['at'].text
    end

    def post_at
      @post_at ||= Time.parse( self.at ).mjd_stamp
    end

    def post_date
      @post_date ||= Time.parse( self.at ).mjd
    end

    def collect_fragment_text( f )
      case f
      when Fragment
        f.text
      when nil
        []
      else
        f.collect { |f| f.text }
      end
    end

    %w[ source keyword regardingurl destinationurl ].each do |f|
      module_eval <<-code
      def #{f}
        collect_fragment_text( fragments['#{f}'] )
      end
      code
    end

    def inflate_others
      tweet_id
      mentions if self.text
      hashtags if self.text
    end

    def status_id
      @status_id ||= ::File.basename( self.url, ".*" )
    end

    def key
      @key ||= "tweet/#{status_id}"
    end

    def author
      @author ||= fragments['actor'].text
    end

    def tokens
      @tokens ||= text.split(/\s+/)
    end

    def mentions
      @mentions ||= tokens.find_all { |t| t[0] == 64 } # look for @
    end

    def hashtags
      @hashtags ||= tokens.find_all { |t| t[0] == 35 } # look for #
    end

    def urls
      @urls ||= ::Addressable::URI.extract( self.text )
    end

    def author_snapshot_key
      @author_snapshot_key ||= "author/#{author}/#{post_date}"
    end

    def to_hash
      h = Hash.new
      Tweet.db_fields.each do |f|
        v = self.send( f )
        case v
        when Array
          v = v.join("\t")
        when nil
          next
        when Fixnum
          v = v.to_s
        when String
          #
        else
          raise "Unknown type conversion for #{f} which is of class #{v.class}"
        end
        h[f] = v
      end
      return h
    end

  private
    def purge_token_based_fields
      @tokens = nil
      @hashtags = nil
      @mentions =nil
    end
  end
end
