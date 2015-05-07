class Applitools::Selenium::Element
  attr_accessor :driver, :web_element

  ELEMENT_METHODS = [
    :hash, :id, :id=, :bridge=, :submit, :clear, :tag_name, :attribute,
    :selected?, :enabled?, :displayed?, :text, :css_value, :find_element,
    :find_elements, :location, :size, :location_once_scrolled_into_view,
    :ref, :to_json, :as_json
                ]

  ELEMENT_METHODS.each do |method|
    define_method method do |*args, &block|
      web_element.send(method,*args, &block)
    end
  end
  alias_method :style, :css_value
  alias_method :first, :find_element
  alias_method :all, :find_elements
  alias_method :[], :attribute



  def initialize(driver, element)
    @driver = driver
    @web_element = element
  end

  def click
    current_control = region
    offset = current_control.middle_offset
    driver.eyes.user_inputs << Applitools::Selenium::MouseTrigger.new(:click, current_control, offset)

    web_element.click
  end

  def inspect
    "EyesWebElement" + web_element.inspect
  end

  def ==(other)
    other.kind_of?(web_element.class) && web_element == other
  end
  alias_method :eql?, :==

  def send_keys(*args)
    current_control = region
    Selenium::WebDriver::Keys.encode(args).each do |key|
      driver.eyes.user_inputs << Applitools::Selenium::TextTrigger.new(key.to_s, current_control)
    end

    web_element.send_keys(*args)
  end
  alias_method :send_key, :send_keys

  def region
    point = location
    left, top, width, height  = point.x, point.y, 0, 0

    begin
      dimension = size
      width, height = dimension.width, dimension.height
    rescue
      # Not supported on all platforms.
    end

    if left < 0
      width = [0, width + left].max
      left = 0
    end

    if top < 0
      height = [0, height + top].max
      top = 0
    end

    return Applitools::Selenium::Region.new(left, top, width, height)
  end
end
