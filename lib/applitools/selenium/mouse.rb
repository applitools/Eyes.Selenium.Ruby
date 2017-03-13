module Applitools::Selenium
  # @!visibility private
  class Mouse
    attr_reader :driver, :mouse

    def initialize(driver, mouse)
      @driver = driver
      @mouse = mouse
    end

    def click(element = nil)
      extract_trigger_and_perform(:click, element)
    end

    def double_click(element = nil)
      extract_trigger_and_perform(:double_click, element)
    end

    def context_click(element = nil)
      extract_trigger_and_perform(:right_click, element)
    end

    def down(element = nil)
      extract_trigger_and_perform(:down, element)
    end

    def up(element = nil)
      extract_trigger_and_perform(:up, element)
    end

    def move_to(element, right_by = nil, down_by = nil)
      element = element.web_element if element.is_a?(Applitools::Selenium::Element)
      location = element.location
      location.x = [0, location.x].max.round
      location.y = [0, location.y].max.round
      current_control = Applitools::Base::Region.new(0, 0, *location.values)
      driver.user_inputs << Applitools::Base::MouseTrigger.new(:move, current_control, location)
      element = element.web_element if element.is_a?(Applitools::Selenium::Element)
      mouse.move_to(element, right_by, down_by)
    end

    def move_by(right_by, down_by)
      right = [0, right_by].max.round
      down = [0, down_by].max.round
      location = Applitools::Base::Point.new(right, down)
      current_control = Applitools::Base::Region.new(0, 0, right, down)
      driver.user_inputs << Applitools::Base::MouseTrigger.new(:move, current_control, location)
      mouse.move_by(right_by, down_by)
    end

    private

    def extract_trigger_and_perform(method, element = nil, *args)
      location = element.location
      location.x = [0, location.x].max.round
      location.y = [0, location.y].max.round
      current_control = Applitools::Base::Region.new(0, 0, *location.values)
      driver.user_inputs << Applitools::Base::MouseTrigger.new(method, current_control, location)
      element = element.web_element if element.is_a?(Applitools::Selenium::Element)
      mouse.send(method, element, *args)
    end
  end
end
