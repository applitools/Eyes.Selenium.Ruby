module Applitools::Selenium
  class NopRegionVisibilityStrategy

    extend Forwardable

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    def move_to_region(position_provider, location)
      logger.info('Ignored (no op).')
    end

    def return_to_original_position(position_provider)
      logger.info('Ignored (no op).')
    end
  end
end