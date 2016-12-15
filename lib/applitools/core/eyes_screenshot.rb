module Applitools::Core
  class EyesScreenshot
    extend Forwardable
    extend Applitools::Core::Helpers

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=
    attr_accessor :image

    COORDINATE_TYPES = {
      screenshot_as_is: 'SCREENSHOT_AS_IS',
      context_relative: 'CONTEXT_RELATIVE'
    }.freeze

    def initialize(screenshot)
      Applitools::Core::ArgumentGuard.is_a? screenshot, 'screenshot', Applitools::Core::Screenshot
      self.image = screenshot
    end

    abstract_method :sub_screenshot, false
    abstract_method :convert_location, false
    abstract_method :location_in_screenshot, false
    abstract_method :intersected_region, false

    def convert_region_location(region, from, to)
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      Applitools::Core::ArgumentGuard.is_a? region, 'region', Applitools::Core::Region
      return Region.new(0, 0, 0, 0) if region.empty?
      Applitools::Core::ArgumentGuard.not_nil from, 'from'
      Applitools::Core::ArgumentGuard.not_nil to, 'to'

      updated_location = convert_location(region.location, from, to)
      Region.new updated_location.x, updated_location.y, region.width, region.height
    end
  end
end
