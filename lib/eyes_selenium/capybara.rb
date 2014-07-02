require 'eyes_selenium'

# Override create driver to inject into capybara's driver
class Applitools::Eyes
  def test(params={}, &block)
    begin
      previous_driver = Capybara.current_driver
      previous_browser = Capybara.current_session.driver.instance_variable_get(:@browser)
      Capybara.current_driver = :selenium
      Capybara.current_session.driver.instance_variable_set(:@browser, driver)
      open(params)
      yield(self, driver)
      close
    rescue Applitools::EyesError
    ensure 
      abort_if_not_closed
      Capybara.current_session.driver.instance_variable_set(:@browser, previous_browser)
      Capybara.current_driver = previous_driver
    end
  end
end
