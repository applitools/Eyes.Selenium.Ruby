module Applitools::Base
  class ImagePosition
    attr_accessor :image, :position

    def initialize(image, position)
      @image = image
      @position = position
    end
  end
end
