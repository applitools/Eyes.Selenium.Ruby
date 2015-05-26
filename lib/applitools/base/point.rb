module Applitools::Base
  class Point
    attr_accessor :x, :y

    alias_attribute :left, :x
    alias_attribute :top, :y

    TOP_LEFT = Point.new(0, 0)

    def initialize(x, y)
      @x = x
      @y = y
    end

    def to_hash(options = {})
      options[:region] ? { left: left, top: top } : { x: x, y: y }
    end

    def values
      [x, y]
    end
  end
end
