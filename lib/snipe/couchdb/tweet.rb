require 'couchrest'
module Snipe
  module CouchDB
    # The CoucDB model for a Tweet
    class Tweet < ::CouchRest::Document

      # initialize a tweet from a hash, this is typically done from a
      # Gnip::Document
      def initialize( keys )
        if keys.kind_of?( Array ) then
          keys = Hash[ *keys ]
        end

        keys.delete('action')
        super( keys )
        inflate_others
        self['type'] = "Tweet"
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

      def text() self['text']; end
      def text=( t )
        self['text'] = t
        purge_token_based_fields
        inflate_others
        return self['text']
      end

      %w[ actor at regarding source to url ].each do |field|
        module_eval <<-code
        def #{field}
          self['#{field}']
        end

        def #{field}=( val )
          self['#{field}'] = val
        end
        code
      end

      private
      def purge_token_based_fields
        @tokens = nil
        %w[ mentioning hashtags ].each { |k| delete(k) }
      end
    end
  end
end
