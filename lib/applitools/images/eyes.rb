require 'applitools/core/eyes_base'

module Applitools::Images
  class Eyes < Applitools::Core::EyesBase

    attr_accessor :base_agent_id, :screenshot, :inferred_environment, :title
    attr_reader :viewport_size

    def capture_screenshot
      @screenshot
    end

    ##
    # Creates a new eyes object
    #   eyes = Applitools::Images::Eyes.new
    #

    def initialize(server_url = Applitools::Connectivity::ServerConnector::DEFAULT_SERVER_URL)
      super
      self.base_agent_id = 'eyes.images.ruby/1.0.0'
    end

    ##
    # Starts a test. Available options:
    #
    # +:app_name+ - the name of the application under trest. Required.
    #
    # +:test_name+ - the test name. Required
    #
    # +:viewport_size+ - viewport size for the baseline, may be passed as a string (<tt>'800x600'</tt>) or
    # as a hash (<tt>{width: 800, height: 600}</tt>). If ommited, the viewport size will be grabbed from the actual
    # image size
    #
    #   eyes.open app_name: 'my app', test_name: 'my test'

    def open(options = {})
      Applitools::Core::ArgumentGuard.hash options, 'open(options)', [:app_name, :test_name]
      options[:viewport_size] = Applitools::Core::RectangleSize.from_any_argument options[:viewport_size]
      open_base options
    end

    def check_image(options)
      options = {tag: nil, ignore_mistmatch: false}.merge options

      if disabled?
        logger.info "check_image(image, #{options[:tag]}, #{options[:ignore_mistmatch]}): Ignored"
        return false
      end

      image = get_image_from_options options

      # options:
      # image_path
      # image_bytes
      # image
      #
      # tag
      # ignore_mistmatch = false

      logger.info "check_image(image, #{options[:tag]}, #{options[:ignore_mistmatch]})"
      if image.is_a? Applitools::Core::Screenshot
        self.viewport_size = Applitools::Core::RectangleSize.new image.width, image.height if viewport_size.nil?
        self.screenshot = EyesImagesScreenshot.new image
      end
      self.title = options[:tag] || ''
      region_provider = Object.new
      region_provider.instance_eval do
        define_singleton_method :region do
          Applitools::Core::Region::EMPTY
        end

        define_singleton_method :coordinate_type do
          nil
        end
      end
      mr = check_window_base region_provider, options[:tag], options[:ignore_mistmatch], Applitools::Core::EyesBase::USE_DEFAULT_TIMEOUT
      mr.as_expected?
    end

    def check_region(options)
      options = {tag: nil, ignore_mistmatch: false}.merge options

      if disabled?
        logger.info "check_region(image, #{options[:tag]}, #{options[:ignore_mistmatch]}): Ignored"
        return false
      end

      Applitools::Core::ArgumentGuard.not_nil options[:region], 'options[:region] can\'t be nil!'
      image = get_image_from_options options

      logger.info "check_region(image, #{options[:region]}, #{options[:tag]}, #{options[:ignore_mistmatch]})"

      if image.is_a? Applitools::Core::Screenshot
        self.viewport_size = Applitools::Core::RectangleSize.new image.width, image.height if viewport_size.nil?
        self.screenshot = EyesImagesScreenshot.new image
      end
      self.title = options[:tag] || ''

      region_provider = Object.new
      region_provider.instance_eval do
        define_singleton_method :region do
          options[:region]
        end
        define_singleton_method :coordinate_type do
          Applitools::Core::EyesScreenshot::COORDINATE_TYPES[:screenshot_as_is]
        end
      end
      mr = check_window_base region_provider, options[:tag], options[:ignore_mistmatch], Applitools::Core::EyesBase::USE_DEFAULT_TIMEOUT
      mr.as_expected?
    end

    def add_mouse_trigger(action, control, cursor)
      add_mouse_trigger_base action, control, cursor
    end

    def add_text_trigger(control, text)
      add_text_trigger_base control, text
    end

    private

    def viewport_size=(value)
      raise Applitools::EyesIllegalArgument.new 'Expected viewport size to be a Applitools::Core::RectangleSize!' unless
          value.nil? || value.is_a?(Applitools::Core::RectangleSize)
      @viewport_size = value
    end

    def get_image_from_options(options)
      unless options[:image].present? && options[:image].is_a?(Applitools::Core::Screenshot)
        image = case
                  when options[:image_path].present?
                    Applitools::Core::Screenshot.new ChunkyPNG::Datastream.from_file(options[:image_path]).to_s
                  when options[:image_bytes].present?
                    Applitools::Core::Screenshot.new options[:image_bytes]
                  else
                    nil
                end
      else
        image = options[:image]
      end

      Applitools::Core::ArgumentGuard.not_nil image, 'options[:image] can\'t be nil!'

      image
    end

  end
end
