require 'eyes_selenium'

# Override create driver to inject into capybara's driver.
class Applitools::Eyes
  def test(options = {}, &block)
    begin
      previous_driver = Capybara.current_driver
      previous_browser = Capybara.current_session.driver.instance_variable_get(:@browser)
      Capybara.current_driver = :selenium
      Capybara.current_session.driver.instance_variable_set(:@browser, driver)

      open(options)
      yield(self, driver)
      close
    rescue Exception, Applitools::EyesError => e
      Applitools::EyesLogger.error "Test failed: #{e.message}!"
    ensure
      abort_if_not_closed
      Capybara.current_session.driver.instance_variable_set(:@browser, previous_browser)
      Capybara.current_driver = previous_driver
    end
  end
end
