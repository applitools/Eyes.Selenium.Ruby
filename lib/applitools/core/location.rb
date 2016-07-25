require 'applitools/core/region'
module Applitools::Core
  class Location < Region

    def initialize(x, y)
      super (x,y,0,0)
    end

    TOP_LEFT = Point.new(0, 0)

    def ==(other)
      return super.==(other) unless other.is_a?(Point)
      @x == other.x && @y == other.y
    end

    alias eql? ==

    def hash
      @x.hash & @y.hash
    end

    def to_hash(options = {})
      options[:region] ? { left: left, top: top } : { x: x, y: y }
    end

    def values
      [x, y]
    end

    def offset(other)

    end
  end
end