module Applitools::Selenium
  # @!visibility private
  class Frame
    attr_accessor :reference, :frame_id, :location, :size, :parent_scroll_position
    def initialize(options = {})
      [:reference, :frame_id, :location, :size, :parent_scroll_position].each do |param|
        raise "options[:#{param}] can't be nil" unless options[param]
        send("#{param}=", options[param])
      end

      raise 'options[:location] must be instance of Applitools::Base::Point' unless
          location.is_a? Applitools::Core::Location

      raise 'options[:parent_scroll_position] must be instance of Applitools::Core::Location' unless
          location.is_a? Applitools::Core::Location

      raise 'options[:size] must be instance of Applitools::Core::RectangleSize' unless
          size.is_a? Applitools::Core::RectangleSize

      return if reference.is_a? Applitools::Selenium::Element
      raise 'options[:reference] must be instance of Applitools::Selenium::Element'
    end
  end
end
