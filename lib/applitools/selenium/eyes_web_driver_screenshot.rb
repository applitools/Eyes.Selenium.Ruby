module Applitools::Selenium
  class EyesWebDriverScreenshot < Applitools::Core::EyesScreenshot

    SCREENSHOT_TYPES = {
        viewport: 'VIEPORT',
        entire_frame: 'ENTIRE_FRAME'
    }.freeze

    # public EyesWebDriverScreenshot(Logger logger,
    #                                       EyesWebDriver driver,
    #                                                     BufferedImage image,
    #                                                                           RectangleSize entireFrameSize)
    #
    # public EyesWebDriverScreenshot(Logger logger, EyesWebDriver driver,
    #                                                             BufferedImage image)
    #
    # public EyesWebDriverScreenshot(Logger logger, EyesWebDriver driver,
    #                                                             BufferedImage image,
    #                                                                           ScreenshotType screenshotType,
    #                                                                                          Location frameLocationInScreenshot)
    attr_accessor :driver

    def initialize(options = {})
      # options = {screenshot_type: SCREENSHOT_TYPES[:viewport]}.merge options
      Applitools::Core::ArgumentGuard.hash options, 'options', [:driver, :image]
      Applitools::Core::ArgumentGuard.not_nil options[:driver], 'options[:driver]'
      Applitools::Core::ArgumentGuard.not_nil options[:image], 'options[:image]'
      self.driver = options[:driver]
      self.image = options[:image]
      self.position_provider = Applitools::Selenium::ScrollPositionProvider.new driver


      viewport_size = driver.default_content_viewport_size #method in driver?

      self.frame_chain = driver.frame_chain #method in driver? frame chain is in another branch
      unless frame_chain.size == 0
        frame_size = frame_chain.current_frame_size
      else
        begin
          frame_size = position_provider.entire_size
        rescue
          frame_size = viewport_size
        end
      end

      begin
        self.scroll_position = position_provider.current_position
      rescue
        self.scroll_position = Applitools::Core::Location.new(0,0)
      end

      unless options[:screenshot_type]
        if (image.width <= viewport_size.width && image.height <= viewport_size.height)
          self.screenshot_type = SCREENSHOT_TYPES[:viewport]
        else
          self.screenshot_type = SCREENSHOT_TYPES[:entire_frame]
        end
      else
        self.screenshot_type = options[:screenshot_type]
      end

      unless options[:frame_location_in_screenshot]
        if frame_chain.size > 0
          self.frame_location_in_screenshot =  calc_frame_location_in_screenshot
        else
          self.frame_location_in_screenshot = Applitools::Core::Location.new(0,0)
          frame_location_in_screenshot.offset Applitools::Core::Location.for(-scroll_position.x, -scroll_position.y) if
              screenshot_type == SCREENSHOT_TYPES[:viewport]
        end
      end

      logger.info 'Calculating frame window..'
      self.frame_window = Applitools::Core::Region.from_location_size(frame_location_in_screenshot, frame_size);
      frame_window.intersect Applitools::Core::Region.new(0, 0, image.width, image.height)

      raise Applitools::EyesException.new 'Got empty frame window for screenshot!' if
          (frame_window.width <= 0 || frame_window.height <= 0)

      logger.info 'Done!'
    end

    def conver_location

    end

    def frame_chain

    end

    def frame_window

    end

    def intersected_region

    end

    def location_in_screenshot

    end

    def sub_screenshot

    end

    private

    attr_accessor :position_provider, :frame_chain, :scroll_position, :screenshot_type, :frame_location_in_screenshot,
                  :frame_window

    def calc_frame_location_in_screenshot
      ##stub - need to implement
    end
  end
end