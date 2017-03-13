module Applitools::Selenium
  # @!visibility private
  class NopRegionVisibilityStrategy
    extend Forwardable

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=

    def move_to_region(_position_provider, _location)
      logger.info('Ignored (no op).')
    end

    def return_to_original_position(_position_provider)
      logger.info('Ignored (no op).')
    end
  end
end
