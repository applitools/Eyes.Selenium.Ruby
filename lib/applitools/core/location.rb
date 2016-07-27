require 'applitools/core/region'
module Applitools::Core
  class Location
    attr_reader :x, :y

    alias left x
    alias top y

    def initialize(x, y)
      @x = x
      @y = y
    end

    TOP_LEFT = Location.new(0, 0)

    def ==(other)
      return super.==(other) unless other.is_a?(Location)
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
      @x += other.x
      @y += other.y
    end
  end
end