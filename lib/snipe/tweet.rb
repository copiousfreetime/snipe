require 'orderedhash'
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
        @text       = StringIO.new
      end

      def add_text( x )
        @text.write( x )
      end

      def text
        @text.string
      end
    end


    # initialize a tweet from a fragment this is typically done from a Gnip
    # Document
    attr_reader :fragments
    def initialize( array = [] )
      @fragments = OrderedHash.new
      unless array.empty? 
        ohash = OrderedHash[ *array ]
        ohash.each_pair do |k,v|
          f = Fragment.new( k )
          f.add_text( v )
          add_fragment( f )
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

    def destination_url
      fragments['destinationurl'].text
    end

    def inflate_others
      tweet_id
      mentioning if self.text
      hashtags if self.text
    end

    def tweet_id
      self['tweet_id'] ||= ::File.basename( self['url'], ".*" )
    end

    def tokens
      @tokens ||= text.split(/\s+/)
    end

    def mentioning
      self['mentioning'] ||= tokens.find_all { |t| t[0] == 64 } # look for @
    end

    def hashtags
      self['hashtags'] ||= tokens.find_all { |t| t[0] == 35 } # look for #
    end

  private
    def purge_token_based_fields
      @tokens = nil
      %w[ mentioning hashtags ].each { |k| delete(k) }
    end
  end
end
