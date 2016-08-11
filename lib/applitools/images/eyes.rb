require 'applitools/core/eyes_base'

module Applitools::Images
  class Eyes < Applitools::Core::EyesBase

    attr_accesor :base_agent_id

    def initialize(server_url = Applitools::Connectivity::ServerConnector::DEFAULT_SERVER_URL)
      super
      self.base_agent_id = 'eyes.images.ruby.0.1'
    end

    def open(options = {})
      Applitools::Core::ArgumentGuard.hash options, 'open(options)', [:app_name, :test_name]
      open_base options
    end

    def check_image(image, tag, ignore_mistmatch)
      if disabled?
        logger.info "chack_image(image, #{tag}, #{ignore_mistmatch}): Ignored"
        return false
      end


    end

    # public boolean checkImage(BufferedImage image, String tag,
    #                                                       boolean ignoreMismatch) {
    #   if (getIsDisabled()) {
    #       logger.verbose(String.format(
    #           "CheckImage(Image, '%s', %b): Ignored", tag,
    #           ignoreMismatch));
    #   return false;
    #   }
    #   ArgumentGuard.notNull(image, "image cannot be null!");
    #
    #   logger.verbose(String.format("CheckImage(Image, '%s', %b)",
    #                                tag, ignoreMismatch));
    #
    #   if (viewportSize == null) {
    #       setViewportSize(
    #           new RectangleSize(image.getWidth(), image.getHeight())
    #       );
    #   }
    #
    #   return checkImage_(new RegionProvider() {
    #     public Region getRegion() {
    #       return Region.EMPTY;
    #     }
    #
    #     public CoordinatesType getCoordinatesType() {
    #       return null;
    #     }
    #   }, image, tag, ignoreMismatch);
    #   }
    #

    def check_region

    end

    def add_mouse_trigger

    end

    def add_text_trigger

    end

  end
end
