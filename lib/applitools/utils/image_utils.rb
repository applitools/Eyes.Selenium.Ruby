require 'oily_png'
require 'base64'

module Applitools::Utils
  QUADRANTS_COUNT = 4.freeze

  module ImageUtils
    extend self

    # Creates an image object from the PNG bytes.
    # +png_bytes+:: +String+ A binary string of the PNG bytes of the image.
    #
    # Returns:
    # +ChunkyPNG::Canvas+ An image object.
    def png_image_from_bytes(png_bytes)
      ChunkyPNG::Image.from_blob(png_bytes)
    end

    # Creates an image instance from a base64 representation of its PNG encoding.
    #
    # +png_bytes64+:: +String+ The Base64 representation of a PNG image.
    #
    # Returns:
    # +ChunkyPNG::Canvas+ An image object.
    def png_image_from_base64(png_bytes64)
      png_image_from_bytes(Base64.decode64(png_bytes64))
    end

    # Get the raw PNG bytes of an image.
    #
    # +ChunkyPNG::Canvas+ The image object for which to get the PNG bytes.
    #
    # Returns:
    # +String+ The PNG bytes of the image.
    def bytes_from_png_image(image)
      image.to_blob
    end

    # Get the Base64 representation of the raw PNG bytes of an image.
    #
    # +ChunkyPNG::Canvas+ The image object for which to get the PNG bytes.
    #
    # Returns:
    # +String+ the Base64 representation of the raw PNG bytes of an image.
    def base64_from_png_image(image)
      Base64.encode64(bytes_from_png_image(image))
    end

    # Rotates a matrix 90 deg clockwise or counter clockwise (depending whether num_quadrants is positive or negative,
    # respectively).
    #
    # +image+:: +ChunkyPNG::Canvas+ The image to rotate.
    # +num_quadrants+:: +Integer+ The number of rotations to perform. Positive values are used for clockwise rotation
    #   and negative values are used for counter-clockwise rotation.
    #
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

    def scale!(image, factor)
      image.resample_nearest_neighbor!(image.width.to_f * factor, image.height.to_f * factor)
    end

    include Applitools::MethodTracer
  end
end
