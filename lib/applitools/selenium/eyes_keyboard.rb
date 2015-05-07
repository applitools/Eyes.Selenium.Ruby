class Applitools::Selenium::Keyboard
  attr_reader :keyboard, :driver

  def initialize(driver, keyboard)
    @driver = driver
    @keyboard = keyboard
  end

  def send_keys(*keys)
    active_element = Applitools::Selenium::Element.new(driver, driver.switch_to.active_element)
    current_control = active_element.region
    Selenium::WebDriver::Keys.encode(keys).each do |key|
      driver.eyes.user_inputs << Applitools::Selenium::TextTrigger.new(key.to_s, current_control)
    end
    keyboard.send_keys(*keys)
  end

  def press(key)
    keyboard.press(key)
  end

  def release(key)
    keyboard.release(key)
  end
end
