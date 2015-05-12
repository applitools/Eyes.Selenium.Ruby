class Applitools::Selenium::Dimension
  attr_accessor :width, :height

  def initialize(width, height)
    @width = width
    @height = height
  end

  def to_hash
    {width: width, height: height}
  end
  def values
    [width, height]
  end
end
