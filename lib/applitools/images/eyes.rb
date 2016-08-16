require 'applitools/core/eyes_base'

module Applitools::Images
  class Eyes < Applitools::Core::EyesBase

    attr_accessor :base_agent_id, :screenshot, :inferred_environment, :title
    attr_reader :viewport_size

    def capture_screenshot
      @screenshot
    end

    def initialize(server_url = Applitools::Connectivity::ServerConnector::DEFAULT_SERVER_URL)
      super
      self.base_agent_id = 'eyes.selenium.ruby/2.33.0'
    end

    def open(options = {})
      Applitools::Core::ArgumentGuard.hash options, 'open(options)', [:app_name, :test_name]
      options[:viewport_size] = Applitools::Core::RectangleSize.from_any_argument options[:viewport_size]
      open_base options
    end

    def check_image(options)
      options = {tag: nil, ignore_mistmatch: false}.merge options
      unless options[:image].present? && options[:image].is_a?(Applitools::Core::Screenshot)
        options[:image] = case
                            when options[:image_path].present?
                              Applitools::Core::Screenshot.new ChunkyPNG::Datastream.from_file(options[:image_path]).to_s
                            when options[:image_bytes].present?
                              Applitools::Core::Screenshot.new options[:image_bytes]
                          end

      end

      Applitools::Core::ArgumentGuard.not_nil options[:image], 'options[:image] can\'t be nil!'

      # options:
      # image_path
      # image_bytes
      # image
      #
      # tag
      # ignore_mistmatch = false


      if disabled?
        logger.info "check_image(image, #{options[:tag]}, #{options[:ignore_mistmatch]}): Ignored"
        return false
      end

      logger.info "check_image(image, #{options[:tag]}, #{options[:ignore_mistmatch]})"
      self.viewport_size = Applitools::Core::RectangleSize.new options[:image].width, options[:image].height if viewport_size.nil?
      self.screenshot = EyesImagesScreenshot.new options[:image] if options[:image].is_a? Applitools::Core::Screenshot
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

    def check_region

    end

    def add_mouse_trigger

    end

    def add_text_trigger(control, text)
      add_text_trigger_base control, text
    end

    private

    def viewport_size= (value)
      raise Applitools::EyesIllegalArgument.new 'Expected viewport size to be a Applitools::Core::RectangleSize!' unless
          value.nil? || value.is_a?(Applitools::Core::RectangleSize)
      @viewport_size = value
    end

  end
end
