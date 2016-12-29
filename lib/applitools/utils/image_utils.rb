require 'oily_png'
require 'base64'
require 'tempfile'

module Applitools::Utils
  # @!visibility private
  QUADRANTS_COUNT = 4
  # @!visibility private
  SCALE_METHODS = {
    :speed => :resample_nearest_neighbor, :quality => :resample_bilinear
  }.freeze

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

    # Scales image by given +scale factor+ by modifying given image
    # @param [Applitools::Core::Screenshot] image An image to scale. (The source image will be modified
    #   by invoking the method)
    # @param [Symbol] scale_method Can be +:speed+ or +:quality+. For further information see ChunkyPNG documentation.
    # @param [Float] factor Scale factor.
    # @return [Applitools::Core::Screenshot]
    def scale!(image, scale_method, factor)
      raise Applitools::EyesIllegalArgument.new "Unknown scale method #{scale_method}" unless
          Applitools::Utils::SCALE_METHODS.keys.include? scale_method
      image.send("#{Applitools::Utils::SCALE_METHODS[scale_method]}!",
        (image.width.to_f * factor).to_i, (image.height.to_f * factor).to_i)
    end

    include Applitools::MethodTracer
  end
end
