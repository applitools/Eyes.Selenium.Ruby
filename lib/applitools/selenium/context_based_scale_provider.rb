module Applitools::Selenium
  # @!visibility private
  class ContextBasedScaleProvider
    UNKNOWN_SCALE_RATIO = 0
    ALLOWED_VS_DEVIATION = 1
    ALLOWED_DCES_DEVIATION = 10

    attr_reader :top_level_context_entire_size, :viewport_size, :device_pixel_ratio, :scale_ratio

    def initialize(top_level_context_entire_size, viewport_size, device_pixel_ratio)
      @top_level_context_entire_size = top_level_context_entire_size
      @viewport_size = viewport_size
      @device_pixel_ratio = device_pixel_ratio
      @scale_ratio = UNKNOWN_SCALE_RATIO
    end

    def scale_image(image)
      if @scale_ratio == UNKNOWN_SCALE_RATIO
        @scale_ratio = if ((image.width >= viewport_size.width - ALLOWED_VS_DEVIATION) &&
            (image.width <= viewport_size.width + ALLOWED_VS_DEVIATION)) ||
            ((image.width >= top_level_context_entire_size.width - ALLOWED_DCES_DEVIATION) &&
            (image.width <= top_level_context_entire_size.width + ALLOWED_DCES_DEVIATION))
                         1
                       else
                         1.to_f / device_pixel_ratio
                       end
      end
      Applitools::Utils::ImageUtils.scale!(image, scale_ratio)
    end

    def scale_ratio
      raise Applitools::EyesError.new 'Scale ratio is not defined yet!' if @scale_ratio == UNKNOWN_SCALE_RATIO
      @scale_ratio
    end
  end
end
