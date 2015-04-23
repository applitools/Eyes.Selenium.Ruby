=begin
Applitools SDK class.

Provides images manipulation functionality.
=end
require 'oily_png'
require 'base64'

module Applitools::Utils::ImageUtils

  # Creates an image object from the PNG bytes.
  # +png_bytes+:: +String+ A binary string of the PNG bytes of the image.
  #
  # Returns:
  # +ChunkyPNG::Canvas+ An image object.
  def self.png_image_from_bytes(png_bytes)
    EyesLogger.debug "#{__method__}()"
    image = ChunkyPNG::Image.from_blob(png_bytes)
    EyesLogger.debug 'Done!'
    return image
  end
    
  # Creates an image instance from a base64 representation of its PNG encoding.
  #
  # +png_bytes64+:: +String+ The Base64 representation of a PNG image.
  #
  # Returns:
  # +ChunkyPNG::Canvas+ An image object.
  def self.png_image_from_base64(png_bytes64)
    EyesLogger.debug "#{__method__}()"
    png_bytes = Base64.decode64(png_bytes64)
    EyesLogger.debug 'Done!'
    return png_image_from_bytes(png_bytes)
  end

  # Get the raw PNG bytes of an image.
  #
  # +ChunkyPNG::Canvas+ The image object for which to get the PNG bytes.
  #
  # Returns:
  # +String+ The PNG bytes of the image.
  def self.bytes_from_png_image(image)
    EyesLogger.debug "#{__method__}()"
    png_bytes = image.to_blob
    EyesLogger.debug 'Done!'
    return png_bytes
  end

  # Get the Base64 representation of the raw PNG bytes of an image.
  #
  # +ChunkyPNG::Canvas+ The image object for which to get the PNG bytes.
  #
  # Returns:
  # +String+ the Base64 representation of the raw PNG bytes of an image.
  def self.base64_from_png_image(image)
    EyesLogger.debug "#{__method__}()"
    png_bytes = bytes_from_png_image(image)
    EyesLogger.debug 'Encoding as base64...'
    image64 = Base64.encode64(png_bytes)
    EyesLogger.debug 'Done!'
    return image64
  end

  # Rotates a matrix 90 deg clockwise or counter clockwise (depending whether num_quadrants is positive or negative,
  # respectively).
  #
  # +image+:: +ChunkyPNG::Canvas+ The image to rotate.
  # +num_quadrants+:: +Integer+ The number of rotations to perform. Positive values are used for clockwise rotation
  #                   and negative values are used for counter-clockwise rotation.
  #
  def self.quadrant_rotate!(image, num_quadrants)
    rotate_method = num_quadrants > 0 ? image.method('rotate_right!'.to_sym) : image.method('rotate_left!'.to_sym)
    (0..(num_quadrants.abs-1)).each { rotate_method.call }
    return image
  end
end