module Applitools::Selenium
  class FullPageCaptureAlgorithm
    extend Forwardable
    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    def get_stiched_region(options = {})
      logger.info 'get_stiched_region() has been invoked.'
      image_provider = options[:image_provider]
      region_provider = options[:region_to_check]
      origin_provider = options[:origin_provider]
      position_provider = options[:position_provider]
      scale_provider = options[:scale_provider]
      cut_provider = options[:cut_provider]
      wait_before_screenshot = options[:wait_before_screenshot]

      logger.info "Region to check: #{region_provider.region}"
      logger.info "Coordinates type: #{region_provider.coordinate_type}"

      original_position = origin_provider.state

      set_position_retries = 3
      while current_position.nil? || (current_position.x !=0 || current_position.y !=0) & set_position_retries > 0  do
        origin_provider.position = Applitools::Core::Location.new 0,0
        sleep wait_before_screenshot
        current_position = origin_provider.current_position
        set_position_retries = set_position_retries - 1
      end




      Applitools::Core::Screenshot.new ChunkyPNG::Image.new(2048, 2048).to_datastream.to_blob

    end
  end
end