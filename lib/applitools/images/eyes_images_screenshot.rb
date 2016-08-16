module Applitools::Images
  class EyesImagesScreenshot < ::Applitools::Core::EyesScreenshot

    SCREENSHOT_AS_IS = Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is].freeze
    CONTEXT_RELATIVE = Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative].freeze

    def initialize(image, options = {})
      super image
      if (location = options[:location]).present?
        Core::ArgumentGuard.is_a? location, 'options[:location]', Core::Location
        @bounds = Core::region.new location.x, location.y, image.width, image.height
      end
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
          if to == CONTEXT_RELATIVE
            result.offset bounds
            return result
          end
          raise "Coordinate type conversation error: #{from} -> #{to}"
        when CONTEXT_RELATIVE
          if to == SCREENSHOT_AS_IS
            result.offset(Applitools::Core::Location.new -bounds.x, -bounds.y)
            return result
          end
          raise "Coordinate type conversation error: #{from} -> #{to}"
        else
          raise "Coordinate type conversation error: #{from} -> #{to}"
      end
    end

    def convert_region_location(region, from, to)
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      return Core::Region.new(0,0,0,0) if region.empty?

      Applitools::Core::ArgumentGuard.not_nil from, 'from'
      Applitools::Core::ArgumentGuard.not_nil to, 'to'

      updated_location = convert_location region.location, from, to

      Applitools::Core::Region.new updated_location.x, updated_location.y, region.width, region.height
    end

    def intersected_region(region, from, to = CONTEXT_RELATIVE)
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      Applitools::Core::ArgumentGuard.not_nil from, 'coordinates Type (from)'

      return Region.new(0,0,0,0) if region.empty?

      intersected_region = convert_region_location region, from, to
      intersected_region.intersect bounds
      return intersected_region if intersected_region.empty?

      intersected_region.location = convert_location intersected_region.location, to, from
      return intersected_region
    end

    private

    def bounds
      @bounds||=Applitools::Core::Region.new(0,0,image.width, image.height)
    end
  end
end