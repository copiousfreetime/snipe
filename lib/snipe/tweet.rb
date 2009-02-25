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
        @text       = []
      end

      def add_text( x )
        @text << x
      end

      def text
        @text.join('')
      end
    end


    # initialize a tweet from a fragment this is typically done from a Gnip
    # Document
    attr_reader   :fragments
    attr_accessor :text

    def initialize( array = [] )
      @fragments = OrderedHash.new
      @text      = nil
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


    def collect_fragment_text( f )
      case f
      when Fragment
        f.text
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
      mentioning if self.text
      hashtags if self.text
    end

    def tweet_id
      @tweet_id ||= ::File.basename( self.url, ".*" )
    end

    def tokens
      @tokens ||= text.split(/\s+/)
    end

    def mentioning
      @mentioning ||= tokens.find_all { |t| t[0] == 64 } # look for @
    end

    def hashtags
      @hashtags ||= tokens.find_all { |t| t[0] == 35 } # look for #
    end

  private
    def purge_token_based_fields
      @tokens = nil
      @hashtags = nil
      @mentioning =nil
    end
  end
end
