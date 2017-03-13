module Applitools::Selenium
  # @!visibility private
  class EyesWebDriverScreenshot < Applitools::Core::EyesScreenshot
    SCREENSHOT_TYPES = {
      viewport: 'VIEPORT',
      entire_frame: 'ENTIRE_FRAME'
    }.freeze

    INIT_CALLBACKS = {
      [:driver, :screenshot_type, :frame_location_in_screenshot].sort => :initialize_main,
      [:driver, :force_offset].sort => :initialize_main,
      [:driver].sort => :initialize_main,
      [:driver, :position_provider].sort => :initialize_main,
      [:driver, :entire_frame_size].sort => :initialize_for_element,
      [:driver, :entire_frame_size, :frame_location_in_screenshot].sort => :initialize_for_element
    }.freeze

    attr_accessor :driver
    attr_accessor :frame_chain
    private :frame_chain=

    class << self
      alias _new new

      def new(*args)
        image = args.shift
        raise Applitools::EyesIllegalArgument.new 'image is expected to be Applitools::Core::Screenshot!' unless
            image.is_a? Applitools::Core::Screenshot

        options = args.first
        if options.is_a? Hash
          result = _new(image)
          callback = INIT_CALLBACKS[options.keys.sort]
          return result.tap { |o| o.send callback, options } if result.respond_to? callback
          raise Applitools::EyesIllegalArgument.new 'Can\'t find an appropriate initializer!'
        end
        raise Applitools::EyesIllegalArgument.new "#{self.class}.initialize(): Hash is expected as an argument!"
      end

      def calc_frame_location_in_screenshot(frame_chain, screenshot_type, logger)
        frame_chain = Applitools::Selenium::FrameChain.new other: frame_chain
        logger.info 'Getting first frame...'
        first_frame = frame_chain.shift
        logger.info 'Done!'
        location_in_screenshot = Applitools::Core::Location.for first_frame.location

        if screenshot_type == SCREENSHOT_TYPES[:viewport]
          default_content_scroll = first_frame.parent_scroll_position
          location_in_screenshot.offset_negative(
            Applitools::Core::Location.for(default_content_scroll.x, default_content_scroll.y)
          )
        end

        logger.info 'Iterating over frames...'
        frame_chain.each do |frame|
          location_in_screenshot.offset(Applitools::Core::Location.for(frame.location.x, frame.location.y))
                                .offset_negative(
                                  Applitools::Core::Location.for(
                                    frame.parent_scroll_position.x, frame.parent_scroll_position.y
                                  )
                                )
        end
        location_in_screenshot
      end
    end

    def initialize_for_element(options = {})
      Applitools::Core::ArgumentGuard.not_nil options[:driver], 'options[:driver]'
      Applitools::Core::ArgumentGuard.not_nil options[:entire_frame_size], 'options[:entire_frame_size]'
      entire_frame_size = options[:entire_frame_size]
      self.driver = options[:driver]
      self.frame_chain = driver.frame_chain
      self.screenshot_type = SCREENSHOT_TYPES[:entire_frame]
      self.scroll_position = Applitools::Core::Location.new(0, 0)
      self.scroll_position = Applitools::Core::Location.new(0, 0).offset(options[:frame_location_in_screenshot]) if
          options[:frame_location_in_screenshot].is_a? Applitools::Core::Location
      self.frame_location_in_screenshot = Applitools::Core::Location.new(0, 0)
      self.frame_window = Applitools::Core::Region.new(0, 0, entire_frame_size.width, entire_frame_size.height)
    end

    def initialize_main(options = {})
      # options = {screenshot_type: SCREENSHOT_TYPES[:viewport]}.merge options

      Applitools::Core::ArgumentGuard.hash options, 'options', [:driver]
      Applitools::Core::ArgumentGuard.not_nil options[:driver], 'options[:driver]'

      self.driver = options[:driver]
      self.position_provider = Applitools::Selenium::ScrollPositionProvider.new driver if
          options[:position_provider].nil?

      viewport_size = driver.default_content_viewport_size

      self.frame_chain = driver.frame_chain
      if !frame_chain.empty?
        frame_size = frame_chain.current_frame_size
      else
        begin
          frame_size = position_provider.entire_size
        rescue
          frame_size = viewport_size
        end
      end

      begin
        self.scroll_position = position_provider.current_position
      rescue
        self.scroll_position = Applitools::Core::Location.new(0, 0)
      end

      if options[:screenshot_type].nil?
        self.screenshot_type = if image.width <= viewport_size.width && image.height <= viewport_size.height
                                 SCREENSHOT_TYPES[:viewport]
                               else
                                 SCREENSHOT_TYPES[:entire_frame]
                               end
      else
        self.screenshot_type = options[:screenshot_type]
      end

      if options[:frame_location_in_screenshot].nil?
        if !frame_chain.empty?
          self.frame_location_in_screenshot = self.class.calc_frame_location_in_screenshot(
            frame_chain, screenshot_type, logger
          )
        else
          self.frame_location_in_screenshot = Applitools::Core::Location.new(0, 0)
        end
      else
        self.frame_location_in_screenshot = options[:frame_location_in_screenshot]
      end

      self.force_offset = Applitools::Core::Location::TOP_LEFT
      self.force_offset = options[:force_offset] if options[:force_offset]

      logger.info 'Calculating frame window..'
      self.frame_window = Applitools::Core::Region.from_location_size(frame_location_in_screenshot, frame_size)
      frame_window.intersect Applitools::Core::Region.new(0, 0, image.width, image.height)

      raise Applitools::EyesError.new 'Got empty frame window for screenshot!' if
          frame_window.width <= 0 || frame_window.height <= 0

      logger.info 'Done!'
    end

    # def scroll_position
    #   begin
    #     position_provider.state
    #   rescue
    #     Applitools::Core::Location.new(0,0)
    #   end
    # end

    def convert_location(location, from, to)
      Applitools::Core::ArgumentGuard.not_nil location, 'location'
      Applitools::Core::ArgumentGuard.not_nil from, 'from'
      Applitools::Core::ArgumentGuard.not_nil to, 'to'

      result = Applitools::Core::Location.for location
      return result if from == to
      # if frame_chain.size.zero? && screenshot_type == SCREENSHOT_TYPES[:entire_frame]
      #   if (from == Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative] ||
      #       from == Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_as_is]) &&
      #       to == Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
      #     result.offset frame_location_in_screenshot
      #   elsif from == Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is] &&
      #       (to == Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative] ||
      #        to == Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_as_is])
      #     result.offset_negative frame_location_in_screenshot
      #   end
      # end

      case from
      when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
        case to
        when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
          result.offset_negative scroll_position
          result.offset frame_location_in_screenshot
        else
          raise Applitools::EyesCoordinateTypeConversionException.new "Can't convert coordinates from #{from} to #{to}"
        end
      when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
        case to
        when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
          result.offset_negative frame_location_in_screenshot
          result.offset scroll_position
        else
          raise Applitools::EyesCoordinateTypeConversionException.new "Can't convert coordinates from #{from} to #{to}"
        end
      else
        raise Applitools::EyesCoordinateTypeConversionException.new "Can't convert coordinates from #{from} to #{to}"
      end

      result
    end

    def frame_chain
      Applitools::Selenium::FrameChain.new other: @frame_chain
    end

    def intersected_region(region, original_coordinate_types, result_coordinate_types)
      return Applitools::Core::Region::EMPTY if region.empty?
      intersected_region = convert_region_location(
        region, original_coordinate_types, Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
      )
      case original_coordinate_types
      when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_as_is]
        nil
      when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
        intersected_region.intersect frame_window
      when Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
        intersected_region.intersect Applitools::Core::Region.new(0, 0, image.width, image.height)
      else
        raise Applitools::EyesCoordinateTypeConversionException.new(
          "Unknown coordinates type: #{original_coordinate_types}"
        )
      end

      return intersected_region if intersected_region.empty?
      convert_region_location(
        intersected_region,
        Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is],
        result_coordinate_types
      )
    end

    def location_in_screenshot(location, coordinate_type)
      location = convert_location(
        location, coordinate_type, Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
      )
      unless frame_window.contains?(location.x, location.y)
        raise Applitools::OutOfBoundsException.new(
          "Location #{location} (#{coordinate_type}) is not visible in screenshot!"
        )
      end
      location
    end

    def sub_screenshot(region, coordinate_type, throw_if_clipped = false)
      logger.info "get_subscreenshot(#{region}, #{coordinate_type}, #{throw_if_clipped})"
      Applitools::Core::ArgumentGuard.not_nil region, 'region'
      Applitools::Core::ArgumentGuard.not_nil coordinate_type, 'coordinate_type'

      region_to_check = Applitools::Core::Region.from_location_size(
        region.location.offset_negative(force_offset), region.size
      )

      as_is_subscreenshot_region = intersected_region region_to_check, coordinate_type,
        Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]

      if as_is_subscreenshot_region.empty? || (throw_if_clipped && !as_is_subscreenshot_region.size == region.size)
        raise Applitools::OutOfBoundsException.new "Region #{region} (#{coordinate_type}) is out" \
          " of screenshot bounds [#{frame_window}]"
      end

      sub_screenshot_image = Applitools::Core::Screenshot.new image.crop(as_is_subscreenshot_region.left,
        as_is_subscreenshot_region.top, as_is_subscreenshot_region.width,
        as_is_subscreenshot_region.height).to_datastream.to_blob

      context_relative_region_location = convert_location as_is_subscreenshot_region.location,
        Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is],
        Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:context_relative]
      result = self.class.new sub_screenshot_image, driver: driver,
        entire_frame_size: Applitools::Core::RectangleSize.new(sub_screenshot_image.width, sub_screenshot_image.height),
        frame_location_in_screenshot: context_relative_region_location
      logger.info 'Done!'
      result
    end

    private

    attr_accessor :position_provider, :scroll_position, :screenshot_type, :frame_location_in_screenshot,
      :frame_window, :force_offset
  end
end
