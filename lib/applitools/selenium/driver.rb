require 'socket'
require 'selenium-webdriver'
require 'appium_lib'

class  Applitools::Selenium::Driver
  # Prepares an image (in place!) for being sent to the Eyes server (e.g., handling rotation, scaling etc.).
  #
  # +driver+:: +Applitools::Selenium::Driver+ The driver which produced the screenshot.
  # +image+:: +ChunkyPNG::Canvas+ The image to normalize.
  # +rotation+:: +Integer+|+nil+ The degrees by which to rotate the image: positive values = clockwise rotation,
  #   negative values = counter-clockwise, 0 = force no rotation, +nil+ = rotate automatically when needed.
  def self.normalize_image!(driver, image, rotation)
    if rotation != 0
      num_quadrants = 0
      if !rotation.nil?
        if rotation % 90 != 0
          raise Applitools::EyesError.new(
            "Currently only quadrant rotations are supported. Current rotation: #{rotation}")
        end
        num_quadrants = (rotation / 90).to_i
      elsif rotation.nil? && driver.mobile_device? && driver.landscape_orientation? && image.height > image.width
        # For Android, we need to rotate images to the right, and for iOS to the left.
        num_quadrants = driver.android? ? 1 : -1
      end
      Applitools::Utils::ImageUtils.quadrant_rotate!(image, num_quadrants)
    end
  end


  include Selenium::WebDriver::DriverExtensions::HasInputDevices

  attr_reader :remote_server_url, :remote_session_id, :screenshot_taker, :eyes
  attr_accessor :driver

  DRIVER_METHODS = [
    :title, :execute_script, :execute_async_script, :quit, :close, :get,
    :post, :page_source, :window_handles, :window_handle, :switch_to,
    :navigate, :manage, :capabilities, :current_url
  ]

  ## If driver is not provided, Applitools::Selenium::Driver will raise an EyesError exception.
  #
  def initialize(eyes, options)
    @driver = options[:driver]
    @is_mobile_device = options.fetch(:is_mobile_device, false)
    @eyes = eyes
    # FIXME fix getting "remote address url" or remove "Screenshot taker" altogether.
    # @remote_server_url = address_of_remote_server
    @remote_server_url = 'MOCK_URL'
    @remote_session_id = remote_session_id

    raise 'Uncapable of taking screenshots!' unless driver.capabilities.takes_screenshot?
  end

  DRIVER_METHODS.each do |method|
    define_method method do |*args, &block|
      driver.send(method,*args, &block)
    end
  end

  # Returns:
  # +String+ The platform name or +nil+ if it is undefined.
  def platform_name
    driver.capabilities['platformName']
  end

  # Returns:
  # +String+ The platform version or +nil+ if it is undefined.
  def platform_version
    version = driver.capabilities['platformVersion']
    version.nil? ? nil : version.to_s
  end

  # Returns:
  # +true+ if the driver is an Android driver.
  def android?
    platform_name.to_s.upcase == 'ANDROID'
  end

  # Returns:
  # +true+ if the driver is an iOS driver.
  def ios?
    platform_name.to_s.upcase == 'IOS'
  end

  # Returns:
  # +true+ if the driver orientation is landscape.
  def landscape_orientation?
    begin
      driver.orientation.to_s.upcase == 'LANDSCAPE'
    rescue NameError
      Applitools::EyesLogger.debug 'driver has no "orientation" attribute. Assuming Portrait.'
    end
  end

  # Returns:
  # +true+ if the platform running the test is a mobile platform. +false+ otherwise.
  def mobile_device?
    # We CAN'T check if the device is an +Appium::Driver+ since it is not a RemoteWebDriver. Because of that we use a
    # flag we got as an option in the constructor.
    @is_mobile_device
  end

  # Return a PNG screenshot in the given format as a string
  #
  # +output_type+:: +Symbol+ The format of the screenshot. Accepted values are +:base64+ and +:png+.
  # +rotation+:: +Integer+|+nil+ The degrees by which to rotate the image: positive values = clockwise rotation,
  #                                 negative values = counter-clockwise, 0 = force no rotation, +nil+ = rotate
  #                                 automatically when needed.
  #
  # Returns: +String+ A screenshot in the requested format.
  def screenshot_as(output_type, rotation=nil)
    # FIXME Check if screenshot_taker is still required
    screenshot = screenshot_taker ? screenshot_taker.screenshot : driver.screenshot_as(:base64)
    screenshot = Applitools::Utils::ImageUtils.png_image_from_base64(screenshot)
    Applitools::Selenium::Driver.normalize_image!(self, screenshot, rotation)
    case output_type
      when :base64
        screenshot = Applitools::Utils::ImageUtils.base64_from_png_image(screenshot)
      when :png
        screenshot = Applitools::Utils::ImageUtils.bytes_from_png_image(screenshot)
      else
        raise Applitools::EyesError.new("Unsupported screenshot output type #{output_type.to_s}")
    end
    screenshot.force_encoding('BINARY')
  end

  def mouse
    Applitools::Selenium::Mouse.new(self, driver.mouse)
  end

  def keyboard
    Applitools::Selenium::Keyboard.new(self, driver.keyboard)
  end

  FINDERS = {
          :class             => 'class name',
          :class_name        => 'class name',
          :css               => 'css selector',
          :id                => 'id',
          :link              => 'link text',
          :link_text         => 'link text',
          :name              => 'name',
          :partial_link_text => 'partial link text',
          :tag_name          => 'tag name',
          :xpath             => 'xpath',
        }

  def find_element(*args)
    how, what = extract_args(args)

    # Make sure that "how" is a valid locator.
    unless FINDERS[how.to_sym]
      raise ArgumentError, "cannot find element by #{how.inspect}"
    end

    Applitools::Selenium::Element.new(self, driver.find_element(how, what))
  end

  def find_elements(*args)
    how, what = extract_args(args)

    unless FINDERS[how.to_sym]
      raise ArgumentError, "cannot find element by #{how.inspect}"
    end

    driver.find_elements(how, what).map { |el| Applitools::Selenium::Element.new(self, el) }
  end

  def ie?
    driver.to_s == 'ie'
  end

  def firefox?
    driver.to_s == 'firefox'
  end

  def user_agent
    execute_script 'return navigator.userAgent'
  rescue => e
    Applitools::EyesLogger.info "getUserAgent(): Failed to obtain user-agent string (#{e.message})"
    return nil
  end

  private

    def remote_session_id
      driver.remote_session_id
    end

    def get_local_ip
      begin
        Socket.ip_address_list.detect do |intf|
          intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast?
        end.ip_address
      rescue SocketError => e
        raise Applitools::EyesError.new("Failed to get local IP! (#{e})")
      end
    end

    def extract_args(args)
      case args.size
      when 2
        args
      when 1
        arg = args.first

        unless arg.respond_to?(:shift)
          raise ArgumentError, "expected #{arg.inspect}:#{arg.class} to respond to #shift"
        end

        # this will be a single-entry hash, so use #shift over #first or #[]
        arr = arg.dup.shift
        unless arr.size == 2
          raise ArgumentError, "expected #{arr.inspect} to have 2 elements"
        end

        arr
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
      end
    end
end

## .bridge, .session_id and .server_url are private methods in Selenium::WebDriver gem
module Selenium::WebDriver
  class Driver
    def remote_session_id
      bridge.session_id
    end
  end

  class Remote::Http::Common
    def get_server_url
      server_url
    end
  end
end
