module Applitools::Selenium
  class EyesTargetLocator < SimpleDelegator
    extend Forwardable

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    attr_reader :driver, :on_will_switch, :scroll_position_provider

    def initialize(driver, original_target_locator, on_will_switch)
      super(original_target_locator)
      @driver = driver
      @on_will_switch = on_will_switch
      @scroll_position_provider = Applitools::Selenium::ScrollPositionProvider.new(driver)
    end

    # @param [Hash] options
    # @option options [Fixnum] :index
    # @option options [String] :name_or_id
    # @option options [WebElement] :frameElement
    # @return [Applitools::Selenium::Driver]
    def frame(options = {})
      raise Applitools::EyesIllegalArgument.new 'You must pass :index or :name_or_id or :frame_element option' unless
          options[:index] || options[:name_or_id] || options[:frame_element]
      if (needed_keys = (options.keys & %i(index name_or_id frame_element))).length == 1
        send "frame_by_#{needed_keys.first}", options[needed_keys.first]
      else
        raise Applitools::EyesIllegalArgument.new 'You\'ve passed some extra keys!' /
          'Only :index, :name_or_id or :frame_elenent are allowed.'
      end
    end

    def parent_frame
      logger.info 'EyesTargetLocator.parent_frame()'
      unless driver.frame_chain.empty?
        on_will_switch.will_switch_to_frame :parent_frame, nil
        logger.info 'Done! Switching to parent_frame...'
        __getobj__.parent_frame
      end
      logger.info 'Done!'
      driver
    end

    # @param [hash] options
    # @option options [Applitools::Selenium::FrameChain] :frame_chain
    # @option options [String] :frames_path
    # @return Applitools::Selenium::Driver
    def frames(options = {})
      raise Applitools::EyesIllegalArgument.new 'You must pass :frame_chain or :frames_path' if
          options[:frame_chain].nil? & options[:frames_path].nil?

      if (needed_keys = (options.keys & %i(frame_chain frames_path))).length == 1
        send "frames_by_#{needed_keys.first}", options[needed_keys.first]
      else
        raise Applitools::EyesIllegalArgument.new 'You\'ve passed some extra keys!' /
          'Only :frame_index or :frames_path are allowed.'
      end
    end

    # A wrapper for the native method +default_content+
    def default_content
      logger.info 'EyesTargetLocator.default_content()'
      unless driver.frame_chain.empty?
        logger.info 'Making preparations...'
        on_will_switch.will_switch_to_frame :default_content, nil
        logger.info 'Done! Switching to default content...'
        __getobj__.default_content
        logger.info 'Done!'
      end
      driver
    end

    # A wrapper for the native method +window+
    def window(name_or_handle)
      logger.info 'EyesTargetLocator.window()'
      logger.info 'Making preparaions...'
      on_will_switch.will_switch_to_window name_or_handle
      logger.info 'Done! Switching to window..'
      __getobj__.window name_or_handle
      logger.info 'Done!'
      driver
    end

    # A wrapper for the native method +active_element+
    def active_element
      logger.info 'EyesTargetLocator.active_element()'
      logger.info 'Switching to element...'
      element = __getobj__.active_element

      unless element.is_a? Selenium::WebDriver::Element
        raise Applitools::EyesError.new(
          'Not an Selenium::WebDriver::Element!'
        )
      end

      result = Applitools::Selenium::Element.new driver, element

      logger.info 'Done!'
      result
    end

    # A wrapper for a native method +alert+
    def alert
      logger.info 'EyesTargetLocator.alert()'
      logger.info 'Switching to alert...'
      result = __getobj__.alert
      logger.info 'Done!'
      result
    end

    private

    def frame_by_index(index)
      raise Applitools::EyesInvalidArgument.new 'You should pass Integer as :index value!' unless index.is_a? Integer
      logger.info "EyesTargetLocator.frame(#{index})"
      logger.info 'Getting frames list...'
      frames = driver.find_elements(:css, 'frame, iframe')
      raise Applitools::EyesNoSuchFrame.new "Frame index #{index} is invalid!" if index >= frames.size

      logger.info 'Done! getting the specific frame...'
      target_frame = frames[index]

      logger.info 'Done! Making preparations...'
      on_will_switch.will_switch_to_frame :frame, target_frame
      logger.info 'Done! Switching to frame...'

      # TODO: Looks like switching to frame by index (Fixnum) doesn't work at least for Chrome browser
      #  Is it better to use __getobj__.frame target_frame instead?
      # __getobj__.frame index
      __getobj__.frame target_frame

      logger.info 'Done!'
      driver
    end

    def frame_by_name_or_id(name_or_id)
      logger.info "EyesTargetLocator.frame(#{name_or_id})"
      # Finding the target element so we can report it.
      # We use find elements(plural) to avoid exception when the element
      # is not found.
      logger.info 'Getting frames by name...'
      frames = driver.find_elements :name, name_or_id
      if frames.empty?
        logger.info 'No frames found! Trying by id...'
        frames = driver.find_elements :id, name_or_id
        raise Applitools::EyesNoSuchFrame.new "No frame with name or id #{name_or_id} exists!" if frames.empty?
      end
      logger.info 'Done! Making preparations...'
      on_will_switch.will_switch_to_frame(:frame, frames.first).last
      logger.info 'Done! Switching to frame...'
      __getobj__.frame frames.first

      logger.info 'Done!'
      driver
    end

    def frame_by_frame_element(web_element)
      logger.info "EyesTargetLocator.frame(element) [#{web_element}]"
      logger.info 'Done! Making preparations...'
      on_will_switch.will_switch_to_frame :frame, web_element
      logger.info 'Done! Switching to frame...'
      __getobj__.frame web_element

      logger.info 'Done!'
      driver
    end

    def frames_by_frame_chain(frame_chain)
      logger.info "EyesTargetLocator.frames(:frame_chain => a_chain) [#{frame_chain}]"
      frame_chain.each do |frame|
        logger.info 'Scrolling by parent scroll position...'
        # scroll_position_provider.scroll_to frame.parent_scroll_position
        logger.info 'Done! Switching to frame...'
        frame frame_element: frame.reference
        logger.info 'Done!'
        logger.info 'Done switching into nested frames!'
        driver
      end
    end

    def frames_by_frames_path(frames_path)
      logger.info 'EyesTargetLocator.frames(:frames_path => a_chain)'
      frames_path.each do |frame_name_or_id|
        logger.info 'Switching to frame...'
        frame(name_or_id: frame_name_or_id)
        logger.info 'Done!'
      end
      logger.info 'Done switching into nested frames!'
      driver
    end
  end
end
