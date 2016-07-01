module Applitools::Base
  Dimension = Struct.new(:width, :height) do
    def to_hash
      {
        width: width,
        height: height
      }
    end

    def values
      [width, height]
    end

    def -(other)
      self.width -= other.width
      self.height -= other.height
      self
    end

    def +(other)
      self.width += other.width
      self.height += other.height
      self
    end

    class << self
      def for(other)
        new(other.width, other.height)
      end
    end
  end
end
