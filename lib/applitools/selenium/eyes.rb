require 'pry'
module Applitools::Selenium
  class Eyes  < Applitools::Core::EyesBase

    UNKNOWN_DEVICE_PIXEL_RATIO = 0
    DEFAULT_DEVICE_PIXEL_RATIO = 1


    DEFAULT_WAIT_BEFORE_SCREENSHOTS = 0.1 # Seconds

    USE_DEFAULT_MATCH_TIMEOUT = -1

    STICH_MODE = {
        scroll: :SCROLL,
        css: :CSS
    }.freeze

    extend Forwardable

    attr_accessor :base_agent_id, :inferred_environment, :screenshot, :region_visibility_strategy
    attr_reader :driver

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    def initialize(server_url = Applitools::Connectivity::ServerConnector::DEFAULT_SERVER_URL)
      super
      self.base_agent_id = "eyes.selenium.ruby/#{Applitools::VERSION})".freeze
      @check_frame_or_element = false
      @region_to_check = nil
      @force_full_page_screenshot = false
      @dont_get_title = false
      @hide_scrollbars = false
      @device_pixel_ratio = UNKNOWN_DEVICE_PIXEL_RATIO
      @stitch_mode = STICH_MODE[:scroll]
      @wait_before_screenshots = DEFAULT_WAIT_BEFORE_SCREENSHOTS
      @region_visibility_strategy = MoveToRegionVisibilityStrategy.new
    end

    def open(options = {})
      driver = options.delete(:driver)
      options[:viewport_size] = Applitools::Core::RectangleSize.from_any_argument options[:viewport_size] if
          options[:viewport_size].present?
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

    # protected WebDriver open(WebDriver driver, String appName, String testName,
    #                                                                   RectangleSize viewportSize, SessionType sessionType) {
    #
    #   if (getIsDisabled()) {
    #       logger.verbose("Ignored");
    #   return driver;
    #   }
    #
    #   openBase(appName, testName, viewportSize, sessionType);
    #
    #   ArgumentGuard.notNull(driver, "driver");
    #
    #   if (driver instanceof RemoteWebDriver) {
    #       this.driver = new EyesWebDriver(logger, this,
    #                                       (RemoteWebDriver) driver);
    #   } else if (driver instanceof EyesWebDriver) {
    #       this.driver = (EyesWebDriver) driver;
    #   } else {
    #       String errMsg = "Driver is not a RemoteWebDriver (" +
    #       driver.getClass().getName() + ")";
    #   logger.log(errMsg);
    #   throw new EyesException(errMsg);
    #   }
    #   devicePixelRatio = UNKNOWN_DEVICE_PIXEL_RATIO;
    #
    #   // Setting the correct position provider.
    #       switch (getStitchMode()) {
    #     case CSS: setPositionProvider(
    #         new CssTranslatePositionProvider(logger, this.driver));
    #     break;
    #     default: setPositionProvider(
    #         new ScrollPositionProvider(logger, this.driver));
    #   }
    #
    #   this.driver.setRotation(rotation);
    #   return this.driver;
    #   }

    def check_window(tag = nil, match_timeout = USE_DEFAULT_MATCH_TIMEOUT)

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
      # if (getIsDisabled()) {
      #     logger.log(String.format("CheckWindow(%d, '%s'): Ignored",
      #                              matchTimeout, tag));
      # return;
      # }
      #
      # logger.log(String.format("CheckWindow(%d, '%s')", matchTimeout,
      #                          tag));
      #
      # super.checkWindowBase(
      #     new RegionProvider() {
      #       public Region getRegion() {
      #         return Region.EMPTY;
      #       }
      #
      #       public CoordinatesType getCoordinatesType() {
      #         return null;
      #       }
      #     },
      #         tag,
      #         false,
      #         matchTimeout
      # );

    end

    def title
      return driver.title unless dont_get_title
    rescue Exception => e
      logger.warn "failed (#{e.message})"
      self.dont_get_title = false
      ''
    end

    def get_viewport_size(web_driver = driver)
      Applitools::Core::ArgumentGuard.not_nil 'web_driver', web_driver
      Applitools::Utils::EyesSeleniumUtils.extract_viewport_size(driver)
    end

    private

    attr_accessor :check_frame_or_element, :region_to_check, :force_full_page_screenshot, :dont_get_title,
                  :hide_scrollbars, :device_pixel_ratio, :stitch_mode, :wait_before_screenshots, :position_provider,
                  :scale_provider

    def capture_screenshot
      logger.info 'Getting screenshot (capture_screenshot() has been invoked)'

      update_scaling_params

      begin
        original_overflow = Applitools::Utils::EyesSeleniumUtils.hide_scrollbars driver
      rescue Applitools::EyesDriverOperationException => e
        Applitools::Logger.warn "Failed to hide scrollbars! Error: #{e.message}"
      end

      begin
        if check_frame_or_element
          logger.info 'Check frame/element requested'
        elsif force_full_page_screenshot
          logger.info 'Full page screenshot requested'
        else
          logger.info 'Screenshot requested...'
          image = driver.visible_screenshot
          scale_provider.scale_image(image)
          # cut_provider.cut(image)
          self.screenshot = Applitools::Selenium::EyesWebDriverScreenshot.new driver: driver, image: image
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

    def check_region(options = {})
      element = options[:element] if options[:element]
      tag = options[:tag] if options[:tag].present?
      match_timeout = option[:match_timeout] if option[:mtch_timeout]

      logger.info "check_region(element, #{match_timeout}, #{tag}): Ignored" and return if disabled?
      Applitools::ArgumentGueard.not_nil 'options[:element]', element
      logger.info "check_region(element: element, #{match_timeout}, #{tag})"

      location_as_point = element.location





    end


    protected

    def check_element(options = {})
      # :element
      # :match_timeout
      # :tag
      tag = options[:tag] if options[:tag].present?
      match_timeout = options[:match_timeout] if options[:match_timeout]

      eyes_element = options[:element] #check it carefully!
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
  end
end

# checkRegion(By selector)
# checkRegion(By selector, boolean stitchContent)
# checkRegion(By selector, int matchTimeout, String tag)
# checkRegion(By selector, int matchTimeout, String tag, boolean stitchContent)
# checkRegion(By selector, String tag)
# checkRegion(By selector, String tag, boolean stitchContent)
# checkRegion(Region region)
# checkRegion(final Region region, int matchTimeout, String tag)
# checkRegion(WebElement element)
# checkRegion(WebElement element, boolean stitchContent)
# checkRegion(final WebElement element, int matchTimeout, String tag)
# checkRegion(WebElement element, int matchTimeout, String tag, boolean stitchContent)
# checkRegion(WebElement element, String tag)
# checkRegion(WebElement element, String tag, boolean stitchContent)





