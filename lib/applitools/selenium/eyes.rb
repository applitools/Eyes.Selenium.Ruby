module Applitools::Selenium
  class Eyes  < Applitools::Core::EyesBase

    UNKNOWN_DEVICE_PIXEL_RATIO = 0
    DEFAULT_DEVICE_PIXEL_RATIO = 1


    DEFAULT_WAIT_BEFORE_SCREENSHOTS = 0.1 # Seconds
    STICH_MODE = {
        scroll: :SCROLL,
        css: :CSS
    }.freeze


    attr_accessor :base_agent_id

    def initialize(server_url = Applitools::Connectivity::ServerConnector::DEFAULT_SERVER_URL)
      super
      self.base_agent_id = "eyes.selenium.ruby/#{Applitools::VERSION})".freeze
      @check_frame_or_element = false
      @region_to_check = null
      @force_full_page_screenshot = false
      @dont_get_title = false
      @hide_scrollbars = false
      @device_pixel_ratio = UNKNOWN_DEVICE_PIXEL_RATIO
      @stitch_mode = STICH_MODE[:scroll]
      @wait_before_screenshots = DEFAULT_WAIT_BEFORE_SCREENSHOTS
      # @region_visibility_strategy = new MoveToRegionVisibilityStrategy(logger)
    end

    def open(options = {})
      driver = options.delete(:driver)
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
          Applitools::EyesLogger.warn("Unrecognized driver type: (#{driver.class.name})!")
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



    private

    attr_accessor :check_frame_or_element, :region_to_check, :force_full_page_screenshot, :dont_get_title,
                  :hide_scrollbars, :device_pixel_ratio, :stitch_mode, :wait_before_screenshots, :position_provider

    def get_driver(options)
      # TODO: remove the "browser" related block when possible. It's for backward compatibility.
      if options.key?(:browser)
        Applitools::EyesLogger.warn('"browser" key is deprecated, please use "driver" instead.')
        return options[:browser]
      end

      options.fetch(:driver, nil)
    end


  end
end