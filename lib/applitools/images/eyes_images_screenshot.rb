module Applitools::Images
  # @!visibility private
  class EyesImagesScreenshot < ::Applitools::Core::EyesScreenshot
    SCREENSHOT_AS_IS = Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is].freeze
    CONTEXT_RELATIVE = Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative].freeze

    def initialize(image, options = {})
      super image
      return if (location = options[:location]).nil?
      Applitools::Core::ArgumentGuard.is_a? location, 'options[:location]', Applitools::Core::Location
      @bounds = Applitools::Core::Region.new location.x, location.y, image.width, image.height
    end

    def convert_location(location, from, to)
      Applitools::Core::ArgumentGuard.not_nil location, 'location'
      Applitools::Core::ArgumentGuard.not_nil from, 'from'
      Applitools::Core::ArgumentGuard.not_nil to, 'to'

      Applitools::Core::ArgumentGuard.is_a? location, 'location', Applitools::Core::Location

      result = Applitools::Core::Location.new location.x, location.y
      return result if from == to

      case from
      when SCREENSHOT_AS_IS
        raise "Coordinate type conversation error: #{from} -> #{to}" unless to == CONTEXT_RELATIVE
        result.offset bounds
        return result
      when CONTEXT_RELATIVE
        raise "Coordinate type conversation error: #{from} -> #{to}" unless to == SCREENSHOT_AS_IS
        result.offset(Applitools::Core::Location.new(-bounds.x, -bounds.y))
        return result
      else
        raise "Coordinate type conversation error: #{from} -> #{to}"
      end
    end

    def convert_region_location(region, from, to)
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      return Core::Region.new(0, 0, 0, 0) if region.empty?

      Applitools::Core::ArgumentGuard.not_nil from, 'from'
      Applitools::Core::ArgumentGuard.not_nil to, 'to'

      updated_location = convert_location region.location, from, to

      Applitools::Core::Region.new updated_location.x, updated_location.y, region.width, region.height
    end

    def intersected_region(region, from, to = CONTEXT_RELATIVE)
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      Applitools::Core::ArgumentGuard.not_nil from, 'coordinates Type (from)'

      return Applitools::Core::Region.new(0, 0, 0, 0) if region.empty?

      intersected_region = convert_region_location region, from, to
      intersected_region.intersect bounds
      return intersected_region if intersected_region.empty?

      intersected_region.location = convert_location intersected_region.location, to, from
      intersected_region
    end

    def location_in_screenshot(location, coordinates_type)
      Applitools::Core::ArgumentGuard.not_nil location, 'location'
      Applitools::Core::ArgumentGuard.not_nil coordinates_type, 'coordinates_type'
      location = convert_location(location, coordinates_type, CONTEXT_RELATIVE)

      unless bounds.contains? location.left, location.top
        raise Applitools::OutOfBoundsException.new "Location #{location} is not available in screenshot!"
      end

      convert_location location, CONTEXT_RELATIVE, SCREENSHOT_AS_IS
    end

    def sub_screenshot(region, coordinates_type, throw_if_clipped)
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      Applitools::Core::ArgumentGuard.not_nil coordinates_type, 'coordinates_type'

      sub_screen_region = intersected_region region, coordinates_type, SCREENSHOT_AS_IS

      if sub_screen_region.empty? || (throw_if_clipped && !region.size_equals?(sub_screen_region))
        Applitools::OutOfBoundsException.new "Region #{sub_screen_region} (#{coordinates_type}) is out of " \
          " screenshot bounds #{bounds}"
      end

      sub_screenshot_image = Applitools::Core::Screenshot.new image.crop(sub_screen_region.left, sub_screen_region.top,
        sub_screen_region.width, sub_screen_region.height).to_datastream.to_blob

      relative_sub_screenshot_region = convert_region_location(sub_screen_region, SCREENSHOT_AS_IS, CONTEXT_RELATIVE)

      Applitools::Images::EyesImagesScreenshot.new sub_screenshot_image,
        location: relative_sub_screenshot_region.location
    end

    private

    def bounds
      @bounds ||= Applitools::Core::Region.new(0, 0, image.width, image.height)
    end
  end
end
