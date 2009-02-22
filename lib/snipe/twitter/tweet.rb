module Snipe
  module Twitter
    # all the data about a tweet
    class Tweet

      def initialize( data )
        @data = data
      end

      def id
        @id ||= File.basename( @data['url'], ".*" )
      end

      def source
        @source ||= @data['source']
      end

      def regarding
        @regarding ||= @data['regarding']
      end

      def author
        @author ||= @data['actor']
      end

      def created_at
        @created_at ||= @data['at']
      end

      def text
        @text ||= @data['text']
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

    end
  end
end
