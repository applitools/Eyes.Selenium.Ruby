module Applitools::Core
  RectangleSize = Struct.new(:width, :height) do
    class << self
      def from_any_argument(value)
        return from_string(value) if value.is_a? String
        return from_hash(value) if value.is_a? Hash
        return from_struct(value) if value.respond_to?(:width) & value.respond_to?(:height)
        return value if value.is_a? self
        nil
      end

      alias_method :for, :from_any_argument

      def from_string(value)
        width, height = value.split(/x/)
        new width, height
      end

      def from_hash(value)
        new value[:width], value[:height]
      end

      def from_struct(value)
        new value.width, value.height
      end
    end

    def to_s
      "#{width}x#{height}"
    end

    def -(other)
      self.width = width - other.width
      self.height = height - other.height
      self
    end

    def +(other)
      self.width = width + other.width
      self.height = height + other.height
      self
    end

    alias_method :to_hash, :to_h
  end
end
