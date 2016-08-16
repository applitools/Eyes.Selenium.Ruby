module Applitools::Core
  RectangleSize = Struct.new(:width, :height) do
    class << self
      def from_any_argument(value)
        return from_string(value) if value.is_a? String
        return from_hash(value) if value.is_a? Hash
        return value if value.is_a? self
        nil
      end

      def from_string(value)
        width, height = value.split /x/
        new width, height
      end
      def from_hash(value)
        new value[:width], value[:height]
      end
    end

    def to_s
      "#{width}x#{height}"
    end

    alias to_hash to_h
  end
end