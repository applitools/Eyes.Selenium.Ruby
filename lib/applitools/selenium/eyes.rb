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


    attr_accessor :base_agent_id, :inferred_environment

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
      # @region_visibility_strategy = new MoveToRegionVisibilityStrategy(logger)
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

      Applitools::EyesLogger.info "check_window(match_timeout: #{match_timeout}, tag: #{tag}): Ignored" if disabled?
      Applitools::EyesLogger.info "check_window(match_timeout: #{match_timeout}, tag: #{tag})"

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
      Applitools::EyesLogger.warn "failed (#{e.message})"
      self.dont_get_title = false
      ''
    end


    private

    attr_accessor :check_frame_or_element, :region_to_check, :force_full_page_screenshot, :dont_get_title,
                  :hide_scrollbars, :device_pixel_ratio, :stitch_mode, :wait_before_screenshots, :position_provider,
                  :scale_provider,

    def capture_screenshot

    end

    def viewport_size=(value)
      raise Applitools::EyesIllegalArgument.new 'Expected viewport size to be a Applitools::Core::RectangleSize!' unless
          value.nil? || value.is_a?(Applitools::Core::RectangleSize)
      @viewport_size = value
    end


    def get_driver(options)
      # TODO: remove the "browser" related block when possible. It's for backward compatibility.
      if options.key?(:browser)
        Applitools::EyesLogger.warn('"browser" key is deprecated, please use "driver" instead.')
        return options[:browser]
      end

      options.fetch(:driver, nil)
    end

    def update_scaling_params
      if device_pixel_ratio == UNKNOWN_DEVICE_PIXEL_RATIO
        Applitools::Logger.info 'Trying to extract device pixel ratio...'
        begin
          self.device_pixel_ratio = Applitools::Utils::EyesSeleniumUtils.device_pixel_ratio(driver)
        rescue EyesDriverOperationException => e
          Applitools::Logger.warn 'Failed to extract device pixel ratio! Using default.'
          self.device_pixel_ratio = DEFAULT_DEVICE_PIXEL_RATIO
        end

        Applitools::Logger.info "Device pixel_ratio: #{device_pixel_ratio}"
        Applitools::Logger.info 'Setting scale provider...'

        begin
          self.scale_provider = Applitools::Selenium::ContextBasedScaleProvider.new(position_provider.entire_size,
            viewport_size, scale_method, device_pixel_ratio)
        rescue => e
          Applitools::Logger.info 'Failed to set ContextBasedScaleProvider'
          Applitools::Logger.info 'Using FixedScaleProvider instead'
          self.scale_provider = Applitools::Selenium::FixedScaleProvider.new(1/device_pixel_ratio)
        end
        logger.info 'Done!'
      end
    end

  end
end