require 'oily_png'
require 'base64'
require 'tempfile'

module Applitools::Utils
  QUADRANTS_COUNT = 4

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
    def png_image_from_base64(png_bytes)
      png_image_from_bytes(Base64.decode64(png_bytes))
    end

    # Get the raw PNG bytes of an image.
    #
    # +ChunkyPNG::Canvas+ The image object for which to get the PNG bytes.
    #
    # Returns:
    # +String+ The PNG bytes of the image.
    def bytes_from_png_image(image)
      image.to_blob(:fast_rgb)
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

    def stitch_images(size, images_data)
      stitched_screenshot = ChunkyPNG::Image.new(size.width, size.height, ChunkyPNG::Color::TRANSPARENT).tap do |res|
        images_data.each do |image_data|
          # Crop out of bounds images.
          image = image_data.image
          position = image_data.position

          new_width = position.left + image.width > size.width ? size.width - position.left : image.width
          new_height = position.top + image.height > size.height ? size.height - position.top : image.height

          if new_width != image.width || new_height != image.height
            image = image.crop!(0, 0, new_width, new_height)
          end

          res.replace!(image.restore, position.left, position.top)
          GC.start
        end
      end
      result = Applitools::Utils::ImageUtils::Screenshot.new stitched_screenshot.to_blob.dup
      GC.start
      result
    end

    class Screenshot < Delegator
      extend Forwardable
      def_delegators :header, :width, :height

      def initialize(image)
        @datastream = ChunkyPNG::Datastream.from_string image
      end

      def to_blob
        @datastream.to_blob
      end

      def __getobj__
        restore
      end

      def header
        @datastream.header_chunk
      end

      def __setobj__(obj)
        @datastream = obj.to_datastream
        self
      end

      def method_missing(method, *args, &block)
        if method =~ /^.+!$/
          __setobj__ super
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super
      end

      def restore
        ChunkyPNG::Image.from_datastream @datastream
      end
    end

    include Applitools::MethodTracer
  end
end
