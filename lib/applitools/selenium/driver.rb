require 'forwardable'
require 'socket'
require 'selenium-webdriver'

module Applitools::Selenium
  class Driver < SimpleDelegator
    extend Forwardable

    include Selenium::WebDriver::DriverExtensions::HasInputDevices

    RIGHT_ANGLE = 90
    IOS = 'IOS'.freeze
    ANDROID = 'ANDROID'.freeze
    LANDSCAPE = 'LANDSCAPE'.freeze

    FINDERS = {
      class: 'class name',
      class_name: 'class name',
      css: 'css selector',
      id: 'id',
      link: 'link text',
      link_text: 'link text',
      name: 'name',
      partial_link_text: 'partial link text',
      tag_name: 'tag name',
      xpath: 'xpath'
    }.freeze

    attr_reader :browser
    attr_accessor :wait_before_screenshots

    def_delegators :@eyes, :user_inputs, :clear_user_inputs
    def_delegators :@browser, :user_agent

    # If driver is not provided, Applitools::Selenium::Driver will raise an EyesError exception.
    def initialize(eyes, options)
      super(options[:driver])
      @is_mobile_device = options.fetch(:is_mobile_device, false)
      @wait_before_screenshots = 0
      @eyes = eyes
      @browser = Applitools::Selenium::Browser.new(self, @eyes)
      Applitools::EyesLogger.warn '"screenshot_as" method not found!' unless driver.respond_to? :screenshot_as
    end

    def execute_script(script)
      raises_error { __getobj__.execute_script(script) }
    end

    # Returns:
    # +String+ The platform name or +nil+ if it is undefined.
    def platform_name
      capabilities['platformName']
    end

    # Returns:
    # +String+ The platform version or +nil+ if it is undefined.
    def platform_version
      version = capabilities['platformVersion']
      version.nil? ? nil : version.to_s
    end

    # Returns:
    # +true+ if the driver orientation is landscape.
    def landscape_orientation?
      driver.orientation.to_s.upcase == LANDSCAPE
    rescue NameError
      Applitools::EyesLogger.debug 'driver has no "orientation" attribute. Assuming: portrait.'
    end

    # Returns:
    # +true+ if the platform running the test is a mobile platform. +false+ otherwise.
    def mobile_device?
      # We CAN'T check if the device is an +Appium::Driver+ since it is not a RemoteWebDriver. Because of that we use a
      # flag we got as an option in the constructor.
      @is_mobile_device
    end

    ## Hide the main document's scrollbars and returns the original overflow value.
    def hide_scrollbars
      @browser.hide_scrollbars
    end

    ## Set the overflow value for document element and return the original overflow value.
    def overflow=(overflow)
      @browser.set_overflow(overflow)
    end

    alias set_overflow overflow=

    # Return a normalized screenshot.
    #
    # +rotation+:: +Integer+|+nil+ The degrees by which to rotate the image: positive values = clockwise rotation,
    #   negative values = counter-clockwise, 0 = force no rotation, +nil+ = rotate automatically when needed.
    #
    # Returns: +ChunkPng::Image+ A screenshot object, normalized by scale and rotation.
    def get_screenshot(rotation = nil)
      image = mobile_device? || !@eyes.force_fullpage_screenshot ? visible_screenshot : @browser.fullpage_screenshot
      Applitools::Selenium::Driver.normalize_image(self, image, rotation)
      image
    end

    def visible_screenshot
      Applitools::EyesLogger.debug "Waiting before screenshot: #{wait_before_screenshots} seconds..."
      sleep(wait_before_screenshots)
      Applitools::EyesLogger.debug 'Finished waiting.'
      Applitools::Utils::ImageUtils::Screenshot.new driver.screenshot_as(:png)
    end

    def mouse
      Applitools::Selenium::Mouse.new(self, driver.mouse)
    end

    def keyboard
      Applitools::Selenium::Keyboard.new(self, driver.keyboard)
    end

    def find_element(*args)
      how, what = extract_args(args)

      # Make sure that "how" is a valid locator.
      raise ArgumentError, "cannot find element by: #{how.inspect}" unless FINDERS[how.to_sym]

      Applitools::Selenium::Element.new(self, driver.find_element(how, what))
    end

    def find_elements(*args)
      how, what = extract_args(args)

      raise ArgumentError, "cannot find element by: #{how.inspect}" unless FINDERS[how.to_sym]

      driver.find_elements(how, what).map { |el| Applitools::Selenium::Element.new(self, el) }
    end

    def android?
      platform_name.to_s.upcase == ANDROID
    end

    def ios?
      platform_name.to_s.upcase == IOS
    end

    private

    def raises_error
      yield if block_given?
    rescue => e
      raise EyesDriverOperationException.new e.message
    end

    def bridge
      __getobj__.send(:bridge)
    end

    def driver
      @driver ||= __getobj__
    end

    def extract_args(args)
      case args.size
      when 2
        args
      when 1
        arg = args.first

        raise ArgumentError, "expected #{arg.inspect}:#{arg.class} to respond to #shift" unless arg.respond_to?(:shift)

        # This will be a single-entry hash, so use #shift over #first or #[].
        arg.dup.shift.tap do |arr|
          raise ArgumentError, "expected #{arr.inspect} to have 2 elements" unless arr.size == 2
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
      end
    end

    class << self
      def normalize_image(driver, image, rotation)
        normalize_rotation(driver, image, rotation)
        normalize_width(driver, image)
      end

      # Rotates the image as necessary. The rotation is either manually forced by passing a value in
      # the +rotation+ parameter, or automatically inferred if the +rotation+ parameter is +nil+.
      #
      # +driver+:: +Applitools::Selenium::Driver+ The driver which produced the screenshot.
      # +image+:: +ChunkyPNG::Canvas+ The image to normalize.
      # +rotation+:: +Integer+|+nil+ The degrees by which to rotate the image: positive values = clockwise rotation,
      #   negative values = counter-clockwise, 0 = force no rotation, +nil+ = rotate automatically when needed.
      def normalize_rotation(driver, image, rotation)
        return if rotation && rotation.zero?

        num_quadrants = 0
        if !rotation.nil?
          if (rotation % RIGHT_ANGLE).nonzero?
            raise Applitools::EyesError.new('Currently only quadrant rotations are supported. Current rotation: '\
            "#{rotation}")
          end
          num_quadrants = (rotation / RIGHT_ANGLE).to_i
        elsif rotation.nil? && driver.mobile_device? && driver.landscape_orientation? && image.height > image.width
          # For Android, we need to rotate images to the right, and for iOS to the left.
          num_quadrants = driver.android? ? 1 : -1
        end

        Applitools::Utils::ImageUtils.quadrant_rotate!(image, num_quadrants)
      end

      def normalize_width(driver, image)
        return if driver.mobile_device?

        normalization_factor = driver.browser.image_normalization_factor(image)
        Applitools::Utils::ImageUtils.scale!(image, normalization_factor) unless normalization_factor == 1
      end
    end
  end
end
