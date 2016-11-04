module Applitools::Selenium
  #@!visibility private
  class MoveToRegionVisibilityStrategy
    extend Forwardable

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=
    attr_accessor :original_position

    def move_to_region(position_provider, location)
      logger.info 'Getting current position state...'
      self.original_position = position_provider.state
      logger.info 'Done! Setting position...'
      position_provider.position = location
      logger.info 'Done!'
    end

    def return_to_original_position(position_provider)
      logger.info 'Returning to original position...'
      position_provider.restore_state original_position
      logger.info 'Done!'
    end
  end
end