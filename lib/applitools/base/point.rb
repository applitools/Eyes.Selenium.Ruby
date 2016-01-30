module Applitools::Base
  class Point
    attr_accessor :x, :y

    alias_attribute :left, :x
    alias_attribute :top, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    TOP_LEFT = Point.new(0, 0)

    def ==(other)
      return super.==(other) unless other.is_a?(Point)
      @x == other.x && @y == other.y
    end

    def hash
      @x.hash & @y.hash
    end

    alias eql? ==

    def to_hash(options = {})
      options[:region] ? { left: left, top: top } : { x: x, y: y }
    end

    def values
      [x, y]
    end
  end
end
