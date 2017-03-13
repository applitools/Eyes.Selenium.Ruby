module Applitools::Selenium
  class CssTranslatePositionProvider
    extend Forwardable

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    attr_accessor :last_state_position

    def initialize(executor)
      self.executor = executor
    end

    def current_position
      last_state_position
    end

    def state
      Applitools::Utils::EyesSeleniumUtils.current_transforms(executor)
    end

    def restore_state(value)
      transforms = value.values.select { |el| !el.empty? }
      Applitools::Utils::EyesSeleniumUtils.set_transforms(executor, value)
      if transforms.empty?
        self.last_state_position = Applitools::Core::Location::TOP_LEFT
      else
        positions = transforms.map { |s| get_position_from_transform(s) }
        positions.each { |p| raise Applitools::EyesError.new 'Got different css positions!' unless p == positions[0] }
        self.last_state_position = positions[0]
      end
    end

    def position=(value)
      Applitools::Core::ArgumentGuard.not_nil(value, 'value')
      logger.info "Setting position to: #{value}"
      Applitools::Utils::EyesSeleniumUtils.translate_to(executor, value)
      logger.info 'Done!'
      self.last_state_position = value
    end

    def force_offset
      Applitools::Core::Location.from_any_attribute last_state_position
    end

    alias scroll_to position=

    def entire_size
      e_size = Applitools::Utils::EyesSeleniumUtils.current_frame_content_entire_size(executor)
      logger.info "Entire size: #{e_size}"
      e_size
    end

    private

    attr_accessor :executor

    def get_position_from_transform(transform)
      regexp = /^translate\(\s*(\-?)(\d+)px,\s*(\-?)(\d+)px\s*\)/
      data = regexp.match(transform)
      raise Applitools::EyesError.new "Can't parse CSS transition: #{transform}!" unless data
      x = data[1].empty? ? data[2].to_i : -1 * data[2].to_i
      y = data[3].empty? ? data[4].to_i : -1 * data[4].to_i
      Applitools::Core::Location.new(x, y)
    end
  end
end
