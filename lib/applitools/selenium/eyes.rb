module Applitools::Selenium
  # The main API gateway for the SDK
  class Eyes  < Applitools::Core::EyesBase

    UNKNOWN_DEVICE_PIXEL_RATIO = 0

    DEFAULT_DEVICE_PIXEL_RATIO = 1

    DEFAULT_WAIT_BEFORE_SCREENSHOTS = 0.1 # Seconds

    USE_DEFAULT_MATCH_TIMEOUT = -1

    # @!visibility private
    STICH_MODE = {
        scroll: :SCROLL,
        css: :CSS
    }.freeze

    extend Forwardable
    # @!visibility public

    # @!attribute [rw] force_full_page_screenshot
    #   Forces a full page screenshot (by scrolling and stitching) if the
    #   browser only ﻿supports viewport screenshots.
    #   @return [boolean] force full page screenshot flag
    # @!attribute [rw] wait_before_screenshots
    #   Sets the time to wait just before taking a screenshot (e.g., to allow
    #   positioning to stabilize when performing a full page stitching).
    #   @return [Float] The time to wait (Seconds). Values
    #     smaller or equal to 0, will cause the default value to be used.

    attr_accessor :base_agent_id, :inferred_environment, :screenshot, :region_visibility_strategy,
                  :force_full_page_screenshot, :wait_before_screenshots, :debug_screenshot
    attr_reader :driver

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    # Creates a new (possibly disabled) Eyes instance that interacts with the
    # Eyes Server at the specified url.
    # @param server_url The Eyes Server URL
    def initialize(server_url = Applitools::Connectivity::ServerConnector::DEFAULT_SERVER_URL)
      super
      self.base_agent_id = "eyes.selenium.ruby/#{Applitools::VERSION})".freeze
      self.check_frame_or_element = false
      self.region_to_check = nil
      self.force_full_page_screenshot = false
      self.dont_get_title = false
      self.hide_scrollbars = false
      self.device_pixel_ratio = UNKNOWN_DEVICE_PIXEL_RATIO
      self.stitch_mode = STICH_MODE[:scroll]
      self.wait_before_screenshots = DEFAULT_WAIT_BEFORE_SCREENSHOTS
      self.region_visibility_strategy = MoveToRegionVisibilityStrategy.new
      self.debug_screenshot = false
    end

    # Starts a test
    # @param options [Hash] options
    # @option options :driver The driver that controls the browser hosting the application under the test. (*Required* option)
    # @option options [String] :app_name The name of the application under the test. (*Required* option)
    # @option options [String] :test_name The test name (*Required* option)
    # @option options [String | Hash] :viewport_size The required browser's viewport size
    #   (i.e., the visible part of the document's body) or +nil+ to use the current window's viewport.
    # @option options :session_type The type of the test (e.g., standard test / visual performance test).
    #   Default value is 'SEQUENTAL'
    # @return [Applitools::Selenium::Driver] A wrapped web driver which enables Eyes trigger recording and frame handling
    def open(options = {})
      driver = options.delete(:driver)
      options[:viewport_size] = Applitools::Core::RectangleSize.from_any_argument options[:viewport_size] if
          options[:viewport_size]
      Applitools::Core::ArgumentGuard.not_nil driver, 'options[:driver]'
      Applitools::Core::ArgumentGuard.hash options, 'open(options)', [:app_name, :test_name]

      if disabled?
        logger.info('Ignored')
        return driver
      end

      if driver.respond_to? :driver_for_eyes
        @driver = driver.driver_for_eyes self
      else
        unless driver.is_a?(Applitools::Selenium::Driver)
          logger.warn("Unrecognized driver type: (#{driver.class.name})!")
          is_mobile_device = driver.respond_to?(:capabilities) && driver.capabilities['platformName']
          @driver = Applitools::Selenium::Driver.new(self, driver: driver, is_mobile_device: is_mobile_device)
        end
      end

      self.device_pixel_ratio = UNKNOWN_DEVICE_PIXEL_RATIO

      case stitch_mode
        when :SCROLL
          self.position_provider = Applitools::Selenium::ScrollPositionProvider.new(driver) #FIXME: what is in the driver?
        when :CSS
          self.position_provider = nil
        else
          self.position_provider = nil
      end

      open_base options
      @driver
    end

    # Takes a snapshot of the application under test and matches it with the expected output.
    # @param [String] tag An optional tag to be assosiated with the snapshot.
    # @param [Fixnum] match_timeout The amount of time to retry matching (seconds)
    def check_window(tag = nil, match_timeout = USE_DEFAULT_MATCH_TIMEOUT)
      self.tag_for_debug = tag
      self.screenshot_name_enumerator = nil
      if disabled?
        logger.info "check_window(#{tag}, #{match_timeout}): Ignored"
        return
      end

      logger.info "check_window(match_timeout: #{match_timeout}, tag: #{tag}): Ignored" if disabled?
      logger.info "check_window(match_timeout: #{match_timeout}, tag: #{tag})"

      region_provider = Object.new
      region_provider.instance_eval do
        define_singleton_method :region do
          Applitools::Core::Region::EMPTY
        end
        define_singleton_method :coordinate_type do
          nil
        end
      end

      check_window_base region_provider, tag, false, match_timeout
    end

    #@!visibilty private
    def title
      return driver.title unless dont_get_title
    rescue Exception => e
      logger.warn "failed (#{e.message})"
      self.dont_get_title = false
      ''
    end

    #@!visibility private
    def get_viewport_size(web_driver = driver)
      Applitools::Core::ArgumentGuard.not_nil 'web_driver', web_driver
      Applitools::Utils::EyesSeleniumUtils.extract_viewport_size(driver)
    end

    # Takes a snapshot of the application under test and matches a region of
    # a specific element with the expected region output.
    # @param [Applitools::Selenium::Element] element Represents a region to check.
    # @param [Symbol] how a finder, such :css or :id. Selects a finder will be used to find an element
    #   See Selenium::Webdriver::Element#find_element documentation for full list of possible finders.
    # @param [String] what The value will be passed to a specified finder. If finder is :css it must be a css selector.
    # @param [Hash] options
    # @option options [String] :tag An optional tag to be associated with the snapshot.
    # @option options [Fixnum] :match_timeout The amount of time to retry matching. (Seconds)
    # @option options [Boolean] :stitch_content If set to true, will try to get full content of the element
    #   (including hidden content due overflow settings) by scrolling the element,
    #   taking and stitching partial screenshots.
    # @example Check region by element
    #   check_region(element, tag: 'Check a region by element', match_timeout: 3, stitch_content: false)
    # @example Check region by css selector
    #   check_region(:css, '.form-row .input#e_mail', tag: 'Check a region by element', match_timeout: 3, stitch_content: false)
    # @!parse def check_region(element, how=nil, what=nil, options = {}); end
    def check_region(*args)
      options = Applitools::Utils.extract_options! args
      self.screenshot_name_enumerator = nil
      if options.delete(:stitch_content)
        check_element args, options
      else
        check_region_ args, options
      end
    end

    # @!parse def check_region(element, how=nil, what=nil, options = {}); end

    # Use this method to perform seamless testing with selenium through eyes driver.
    # It yields a block and passes to it an Applitools::Selenium::Driver instance, which wraps standard driver.
    # Using Selenium methods inside the 'test' block will send the messages to Selenium
    # after creating the Eyes triggers for them. Options are similar to {open}
    # @yieldparam driver [Applitools::Selenium::Driver] Gives a driver to a block, which translates calls to a native Selemium::Driver instance
    # @example
    #   eyes.test(app_name: 'my app', test_name: 'my test') do |driver|
    #      driver.get "http://www.google.com"
    #      driver.check_window("initial")
    #   end
    def test(options = {}, &_block)
      open(options)
      yield(driver)
      close
    ensure
      abort_if_not_closed
    end

    private

    attr_accessor :check_frame_or_element, :region_to_check, :dont_get_title,
                  :hide_scrollbars, :device_pixel_ratio, :stitch_mode, :position_provider,
                  :scale_provider, :tag_for_debug

    def capture_screenshot
      image_provider = Applitools::Selenium::TakesScreenshotImageProvider.new driver,
          debug_screenshot: debug_screenshot, name_enumerator: screenshot_name_enumerator
      eyes_screenshot_factory = ->(image) {
        Applitools::Selenium::EyesWebDriverScreenshot.new(image, driver: driver)
      }
      logger.info 'Getting screenshot (capture_screenshot() has been invoked)'

      update_scaling_params

      begin
        original_overflow = Applitools::Utils::EyesSeleniumUtils.hide_scrollbars driver
      rescue Applitools::EyesDriverOperationException => e
        logger.warn "Failed to hide scrollbars! Error: #{e.message}"
      end

      begin
        if check_frame_or_element
          logger.info 'Check frame/element requested'
          algo = Applitools::Selenium::FullPageCaptureAlgorithm.new

          entire_frame_or_element = algo.get_stiched_region(image_provider: image_provider,
                                                            region_to_check: region_to_check,
                                                            origin_provider: position_provider,
                                                            position_provider: position_provider,
                                                            scale_provider: scale_provider,
                                                            cut_provider: nil,
                                                            wait_before_screenshots: wait_before_screenshots,
                                                            eyes_screenshot_factory: eyes_screenshot_factory
                                                           )

          logger.info 'Building screenshot object...'
          self.screenshot = Applitools::Selenium::EyesWebDriverScreenshot.new entire_frame_or_element,
              driver: driver,
              entire_frame_size: Applitools::Core::RectangleSize.new(entire_frame_or_element.width,
                                                                     entire_frame_or_element.height)
        elsif force_full_page_screenshot
          logger.info 'Full page screenshot requested'
          original_frame = driver.frame_chain
          driver.switch_to.default_content
          algo = Applitools::Selenium::FullPageCaptureAlgorithm.new
          region_provider = Object.new
          region_provider.instance_eval do
            def region
              Applitools::Core::Region::EMPTY
            end

            def coordinate_type
              nil
            end
          end
          full_page_image = algo.get_stiched_region image_provider: image_provider,
                                  region_to_check: region_provider,
                                  origin_provider: Applitools::Selenium::ScrollPositionProvider.new(driver),
                                  position_provider: position_provider,
                                  scale_provider: scale_provider,
                                  cut_provider: nil,
                                  wait_before_screenshots: wait_before_screenshots,
                                  eyes_screenshot_factory: eyes_screenshot_factory

          # driver.switch_to.frame original_frame
          Applitools::Selenium::EyesWebDriverScreenshot.new full_page_image, driver: driver
        else
          logger.info 'Screenshot requested...'
          image = image_provider.take_screenshot
          scale_provider.scale_image(image) if scale_provider
          cut_provider.cut(image) if cut_provider
          self.screenshot = Applitools::Selenium::EyesWebDriverScreenshot.new image, driver: driver
        end
      ensure
        begin
          Applitools::Utils::EyesSeleniumUtils.set_overflow driver, original_overflow
        rescue Applitools::EyesDriverOperationException => e
          logger.warn "Failed to revert overflow! Error: #{e.message}"
        end
      end
    end

    def set_viewport_size(value)
      raise Applitools::EyesNotOpenException.new 'set_viewport_size: Eyes not open!' unless open?
      original_frame = driver.frame_chain
      # driver.switch_to.default_content
      begin
        Applitools::Utils::EyesSeleniumUtils.set_viewport_size driver, value
      rescue => e
        logger.error e.class
        logger.error e.message
        raise Applitools::TestFailedError.new 'Failed to set viewport size!'
      ensure
        # driver.switch_to.frames(original_frame)
      end
    end

    def get_driver(options)
      # TODO: remove the "browser" related block when possible. It's for backward compatibility.
      if options.key?(:browser)
        logger.warn('"browser" key is deprecated, please use "driver" instead.')
        return options[:browser]
      end

      options.fetch(:driver, nil)
    end

    def update_scaling_params
      if device_pixel_ratio == UNKNOWN_DEVICE_PIXEL_RATIO
        logger.info 'Trying to extract device pixel ratio...'
        begin
          self.device_pixel_ratio = Applitools::Utils::EyesSeleniumUtils.device_pixel_ratio(driver)
        rescue Applitools::EyesDriverOperationException => e
          logger.warn 'Failed to extract device pixel ratio! Using default.'
          self.device_pixel_ratio = DEFAULT_DEVICE_PIXEL_RATIO
        end

        logger.info "Device pixel_ratio: #{device_pixel_ratio}"
        logger.info 'Setting scale provider...'

        begin
          self.scale_provider = Applitools::Selenium::ContextBasedScaleProvider.new(position_provider.entire_size,
            viewport_size, scale_method, device_pixel_ratio)
        rescue => e
          logger.info 'Failed to set ContextBasedScaleProvider'
          logger.info 'Using FixedScaleProvider instead'
          self.scale_provider = Applitools::Selenium::FixedScaleProvider.new(1/device_pixel_ratio)
        end
        logger.info 'Done!'
      end
    end

    def _add_text_trigger(control, text)
      unless(last_screenshot)
        logger.info "Ignoring #{text} (no screenshot)"
        return
      end

      # if (!FrameChain.isSameFrameChain(driver.getFrameChain(),
      #                                  ((EyesWebDriverScreenshot) lastScreenshot).getFrameChain())) {
      #     logger.verbose(String.format("Ignoring '%s' (different frame)",
      #                                  text));
      # return;
      # }

      add_text_trigger_base(control, text)
    end

    def add_text_trigger(control, text)
      if disabled?
        logger.info "Ignoring #{text} (disabled)"
        return
      end

      Applitools::Core::ArgumentGuard.not_nil control, 'control'
      if control.is_a? Applitools::Core::Region
        return _add_text_trigger(control, text)
      elsif control.is_a? Applitools::Selenium::Element
        pl = control.location
        ds = control.size

        element_region = Applitools::Core::Region.new(pl.x, pl.y, ds.width, ds.height)

        return _add_text_trigger(element_region, text)
      end
    end

    def add_mouse_trigger(mouse_action, element)
      if disabled?
        logger.info "Ignoring #{mouse_action} (disabled)"
        return
      end

      if (element.is_a? Hash)
        return add_mouse_trigger_by_region_and_location(mouse_action, element[:region], element[:location]) if
            element.key?(:location) && element.key?(:region)
        raise Applitools::EyesIllegalArgument.new 'Element[] doesn\'t contain required keys!'
      end

      Applitools::Core::ArgumentGuard.not_nil element, 'element'
      Applitools::Core::ArgumentGuard.is_a? element, 'element', Applitools::Selenium::Element

      pl = element.location
      ds = element.size

      element_region = Applitools::Core::Region.new(pl.x, pl.y, ds.width, ds.height)

      unless(last_screenshot)
        logger.info "Ignoring #{mouse_action} (no screenshot)"
        return
      end

      # if (!FrameChain.isSameFrameChain(driver.getFrameChain(),
      #                                  ((EyesWebDriverScreenshot) lastScreenshot).getFrameChain())) {
      #     logger.verbose(String.format("Ignoring %s (different frame)",
      #                                  action));
      # return;
      # }

      element_region = last_screenshot.intersected_region(element_region,
                                                          Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative],
                                                          Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
      )

      add_mouse_trigger_base(mouse_action, element_region, element_region.middle_offset)
    end

    # control - Region
    # cursor - Location
    def add_mouse_trigger_by_region_and_location(mouse_action, control, cursor)
      unless last_screenshot
        logger.info "Ignoring #{mouse_action} (no screenshot)"
        return
      end

      Applitools::Core::ArgumentGuard.is_a? control, 'control', Applitools::Core::Region
      Applitools::Core::ArgumentGuard.is_a? cursor, 'cursor', Applitools::Core::Location

      # if (!FrameChain.isSameFrameChain(driver.getFrameChain(),
      #                                  ((EyesWebDriverScreenshot) lastScreenshot).getFrameChain())) {
      #     logger.verbose(String.format("Ignoring %s (different frame)",
      #                                  action));
      # return;
      # }

      add_mouse_trigger_base(mouse_action, control, cursor)
    end

    protected
    #testtesttest
    #@param [Hash]options
    #@option options [Region] :region
    def check_region_(element_or_selector, options = {})
      # :element
      # :selector
      # :tag
      # :match_timeout
      # :stitch_content
      selector = element_or_selector if Applitools::Selenium::Driver::FINDERS.keys.include? element_or_selector.first
      element = element_or_selector.first if element_or_selector.first.instance_of? Applitools::Selenium::Element
      element = driver.find_element(*selector) unless element
      raise Applitools::EyesIllegalArgument.new 'You should pass :selector or :element!' unless element

      if !options[:tag].nil? && !options[:tag].empty?
        tag = options[:tag]
        self.tag_for_debug = tag
      end

      match_timeout = options[:match_timeout] || USE_DEFAULT_MATCH_TIMEOUT

      logger.info "check_region(element, #{match_timeout}, #{tag}): Ignored" and return if disabled?
      Applitools::Core::ArgumentGuard.not_nil 'options[:element]', element
      logger.info "check_region(element: element, #{match_timeout}, #{tag})"

      location_as_point = element.location
      region_visibility_strategy.move_to_region position_provider, Applitools::Core::Location.new(location_as_point.x, location_as_point.y)

      region_provider = Object.new.tap do |prov|
        prov.instance_eval do
          define_singleton_method :region do
            p = element.location
            d = element.size
            Applitools::Core::Region.from_location_size p, d
          end

          define_singleton_method :coordinate_type do
            Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
          end
        end
      end

      result = check_window_base region_provider, tag, false, match_timeout

      logger.info 'Done! trying to scroll back to original position...'
      region_visibility_strategy.return_to_original_position position_provider
      logger.info 'Done!'
      result
    end

    def check_element(element_or_selector, options = {})
      # :selector
      # :element
      # :match_timeout
      # :tag
      selector = element_or_selector if Applitools::Selenium::Driver::FINDERS.keys.include? element_or_selector.first
      if !options[:tag].nil? && !options[:tag].empty?
        tag = options[:tag]
        self.tag_for_debug = tag
      end
      match_timeout = options[:match_timeout] || USE_DEFAULT_MATCH_TIMEOUT

      if disabled?
        logger.info "check_element(#{options.inject([]) {|res, p| res << "#{p.first}: #{p.last}"}.join(', ')}): Ignored"
        return
      end

      eyes_element = element_or_selector.first if element_or_selector.first.instance_of? Applitools::Selenium::Element
      eyes_element = driver.find_element(*selector) unless eyes_element
      raise Applitools::EyesIllegalArgument.new 'You should pass :selector or :element!' unless eyes_element
      eyes_element = Applitools::Selenium::Element.new(driver, eyes_element) unless eyes_element.is_a? Applitools::Selenium::Element
      original_overflow = nil
      original_position_provider = position_provider
      begin
        self.check_frame_or_element = true
        self.position_provider = Applitools::Selenium::ElementPositionProvider.new driver, eyes_element
        original_overflow = eyes_element.overflow
        eyes_element.overflow = 'hidden'

        p = eyes_element.location
        d = eyes_element.size

        border_left_width = eyes_element.border_left_width
        border_top_width = eyes_element.border_top_width
        border_right_width = eyes_element.border_right_width
        border_bottom_width = eyes_element.border_bottom_width

        element_region = Applitools::Core::Region.new(
          p.x + border_left_width,
          p.y + border_top_width,
          d.width - border_left_width - border_right_width,
          d.height - border_top_width - border_bottom_width
        )

        logger.info "Element region: #{element_region}"

        self.region_to_check = Object.new.tap do |prov|
          prov.instance_eval do
            define_singleton_method :region do
              element_region
            end

            define_singleton_method :coordinate_type do
              Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
            end
          end
        end

        base_check_region_provider = Object.new.tap do |prov|
          prov.instance_eval do
            define_singleton_method :region do
              Applitools::Core::Region::EMPTY
            end

            define_singleton_method :coordinate_type do
              nil
            end
          end
        end
        check_window_base base_check_region_provider, tag, false, match_timeout
      ensure
        eyes_element.overflow = original_overflow unless original_overflow.nil?
        self.check_frame_or_element = false
        self.position_provider = original_position_provider
        self.region_to_check = nil
      end
    end

    def screenshot_name_enumerator
      @name_enumerator ||= Enumerator.new do |y|
        counter = 1
        loop do
          y << "#{tag_for_debug.gsub /\s+/, '_'}__#{Time.now.strftime('%Y_%m_%d_%H_%M')}__#{counter}.png"
          counter = counter + 1;
        end
      end
    end

    def screenshot_name_enumerator=(value)
      @name_enumerator = nil unless value
    end
  end
end