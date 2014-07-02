class Applitools::EyesKeyboard
  attr_reader :keyboard, :driver
  
  def initialize(driver, keyboard)
    @driver = driver
    @keyboard = keyboard
  end

  def send_keys(*keys)
    active_element = Applitools::Element.new(driver, driver.switch_to.active_element)
    current_control = active_element.region
    Selenium::WebDriver::Keys.encode(keys).each do |key|
      driver.eyes.user_inputs << Applitools::TextTrigger.new(key.to_s, current_control)
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
