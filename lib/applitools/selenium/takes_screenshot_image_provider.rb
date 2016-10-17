module Applitools::Selenium
  class TakesScreenshotImageProvider
    extend Forwardable
    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    attr_accessor :driver
    def initialize(driver)
      self.driver = driver
    end

    def take_screenshot
      logger.info 'Getting screenshot...'
      screenshot = driver.screenshot_as(:png)
      logger.info 'Done getting screenshot! Creating Applitools::Core::Screenshot...'
      Applitools::Core::Screenshot.new screenshot
    end
  end
end