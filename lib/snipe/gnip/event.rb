module Snipe
  module Gnip
    class Event
      attr_reader :raw
      def initialize( raw )
        @raw = Hash[ *raw ]
      end
      %w[ source regarding to url action actor at ].each do |field|
        module_eval <<-code
        def #{field}
          raw['#{field}']
        end
        code
      end
    end
  end
end
