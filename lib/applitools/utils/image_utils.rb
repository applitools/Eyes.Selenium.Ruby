require 'base64'
require 'tempfile'

module Applitools::Utils
  # @!visibility private
  QUADRANTS_COUNT = 4

  RESAMPLE_INCREMENTALLY_FRACTION = 2

  module ImageUtils
    extend self

    # Creates an image object from the PNG bytes.
    # @param [String] png_bytes A binary string of the PNG bytes of the image.
    # @return [ChunkyPNG::Canvas] An image object.
    def png_image_from_bytes(png_bytes)
      ChunkyPNG::Image.from_blob(png_bytes)
    end

    # Creates an image instance from a base64 representation of its PNG encoding.
    # @param [String] png_bytes The Base64 representation of a PNG image.
    # @return [ChunkyPNG::Canvas] An image object.
    def png_image_from_base64(png_bytes)
      png_image_from_bytes(Base64.decode64(png_bytes))
    end

    # Get the raw PNG bytes of an image.
    # @param [ChunkyPNG::Canvas] image The image object for which to get the PNG bytes.
    # @return [String] The PNG bytes of the image.
    def bytes_from_png_image(image)
      image.to_blob(:fast_rgb)
    end

    # Get the Base64 representation of the raw PNG bytes of an image.
    # @param [ChunkyPNG::Canvas] image The image object for which to get the PNG bytes.
    # @return [String] the Base64 representation of the raw PNG bytes of an image.
    def base64_from_png_image(image)
      Base64.encode64(bytes_from_png_image(image))
    end

    # Rotates a matrix 90 deg clockwise or counter clockwise (depending whether num_quadrants is positive or negative,
    # respectively).
    # @param [ChunkyPNG::Canvas] image The image to rotate.
    # @param [Integer] num_quadrants The number of rotations to perform. Positive values are used for clockwise rotation
    #   and negative values are used for counter-clockwise rotation.
    def quadrant_rotate!(image, num_quadrants)
      num_quadrants %= QUADRANTS_COUNT
      case num_quadrants
      when 0
        image
      when 1
        image.rotate_right!
      when 2
        image.rotate_180!
      when 3
        image.rotate_left!
      end
    end

    # Cuts the image according to passed crop_region. The method mutates an image.
    # @param [ChunkyPNG::Canvas] image The image to cut
    # @param [Applitools::Core::Region] crop_region The region which represents cut bounds.
    #   The area outside crop_region will be removed from the image.
    def cut!(image, crop_region)
      image.crop! crop_region.left, crop_region.top, crop_region.width, crop_region.height
    end

    # Cuts the image according to passed crop_region. The method returns new instance of the image
    # without changing the source image.
    # @param [ChunkyPNG::Canvas] image The image to cut
    # @param [Applitools::Core::Region] crop_region The region which represents cut bounds.
    #   The area outside crop_region will be removed from the image.
    def cut(image, crop_region)
      cut! image.dup, crop_region
    end

    # Scales image by given +scale factor+ by modifying given image
    # @param [Applitools::Core::Screenshot] image An image to scale. (The source image will be modified
    #   by invoking the method)
    # @param [Float] scale_ratio Scale factor.
    # @return [Applitools::Core::Screenshot]
    def scale!(image, scale_ratio)
      return image if scale_ratio == 1
      image_ratio = image.width.to_f / image.height.to_f
      scale_width = (image.width * scale_ratio).ceil
      scale_height = (scale_width / image_ratio).ceil
      resize_image!(image, scale_width, scale_height)
    end

    def scale(image, scale_ratio)
      scale!(image.dup, scale_ratio)
    end

    def resize_image!(image, new_width, new_height)
      Applitools::Core::ArgumentGuard.not_nil(new_width, 'new_width')
      Applitools::Core::ArgumentGuard.not_nil(new_height, 'new_height')
      Applitools::Core::ArgumentGuard.not_nil(image, 'image')
      Applitools::Core::ArgumentGuard.is_a?(image, 'image', Applitools::Core::Screenshot)

      raise Applitools::EyesIllegalArgument.new "Invalid width: #{new_width}" if new_width <= 0
      raise Applitools::EyesIllegalArgument.new "Invalid height: #{new_height}" if new_height <= 0

      return image if image.width == new_width && image.height == new_height

      if new_width > image.width || new_height > image.height
        image.resample_bicubic!(new_width, new_height)
      else
        scale_image_incrementally!(image, new_width, new_height)
      end
    end

    def resize_image(image, new_width, new_height)
      resize_image!(image.dup, new_width, new_height)
    end

    def scale_image_incrementally!(image, new_width, new_height)
      current_width = image.width
      current_height = image.height

      while current_width != new_width || current_height != new_height
        prev_current_width = current_width
        prev_current_height = current_height
        if current_width > new_width
          current_width -= (current_width / RESAMPLE_INCREMENTALLY_FRACTION)
          current_width = new_width if current_width < new_width
        end

        if current_height > new_height
          current_height -= (current_height / RESAMPLE_INCREMENTALLY_FRACTION)
          current_height = new_height if current_height < new_height
        end

        return image if prev_current_width == current_width && prev_current_height == current_height
        Applitools::EyesLogger.debug "Incremental dimensions: #{current_width} x #{current_height}"
        image.resample_bicubic!(current_width, current_height)
      end
      image
    end

    def scale_image_incrementally(image, new_width, new_height)
      scale_image_incrementally!(image.dup, new_width, new_height)
    end

    include Applitools::MethodTracer
  end
end
