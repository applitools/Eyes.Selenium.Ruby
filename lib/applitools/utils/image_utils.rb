require 'oily_png'
require 'base64'

module Applitools::Utils
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
      image.tap do |img|
        rotate_method = num_quadrants > 0 ? img.method(:rotate_right!) : img.method(:rotate_left!)
        (0..(num_quadrants.abs - 1)).each { rotate_method.call }
      end
    end

    include Applitools::MethodTracer
  end
end
