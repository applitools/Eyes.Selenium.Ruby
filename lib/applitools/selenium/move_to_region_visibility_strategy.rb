module Applitools::Selenium
  # @!visibility private
  class MoveToRegionVisibilityStrategy
    extend Forwardable

    VISIBILITY_OFFSET = 100

    def_delegators 'Applitools::EyesLogger', :logger, :log_handler, :log_handler=
    attr_accessor :original_position

    def move_to_region(position_provider, location)
      logger.info 'Getting current position state...'
      self.original_position = position_provider.state

      dst_x = location.x - VISIBILITY_OFFSET
      dst_y = location.y - VISIBILITY_OFFSET

      dst_x = 0 if dst_x < 0
      dst_y = 0 if dst_y < 0

      logger.info "Done! Setting position to #{location}..."

      position_provider.position = Applitools::Core::Location.new(dst_x, dst_y)
      logger.info 'Done!'
    end

    def return_to_original_position(position_provider)
      logger.info 'Returning to original position...'
      position_provider.restore_state original_position
      logger.info 'Done!'
    end
  end
end
