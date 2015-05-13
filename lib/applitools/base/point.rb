class Applitools::Base::Point
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_hash
    {
      x: x,
      y: y
    }
  end

  def values
    [x, y]
  end
end
