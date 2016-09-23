module Applitools::Selenium
  class Frame

    attr_accessor :refernce, :frame_id, :location, :size, :parent_scroll_position
    def initialize(options = {})
      [:refernce, :frame_id, :location, :size, :parent_scroll_position].each do |param|
        raise "options[:#{param}] can't be nil" unless options[param]
        self.send("#{param}=", options[param])
      end
    end
    raise 'options[:location] must be instance of Applitools::Base::Point' unless location.is_a? Applitools::Base::Point
    raise 'options[:parent_scroll_position] must be instance' \
      ' of Applitools::Base::Point' unless location.is_a? Applitools::Base::Point
    raise 'options[:size] must be instance of ' \
      'Applitools::Base::Dimension' unless location.is_a? Applitools::Base::Dimension
    raise 'options[:reference] must be instance of '\
      'Applitools::Selenium::Element' unless location.is_a? Applitools::Selenium::Element
  end
end
