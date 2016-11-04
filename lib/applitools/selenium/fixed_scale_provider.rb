module Applitools::Selenium
  #@!visibility private
  class FixedScaleProvider
    SCALE_METHODS = {
        speed: 'SPEED',
        quality: 'QUALITY',
        ultra_quality: 'ULTRA_QUALITY'
    }.freeze

    def initialize(scale_ratio, method = SCALE_METHODS[:speed] )

    end

    def scale_image(image)
      image
    end
  end
end
