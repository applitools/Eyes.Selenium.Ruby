require 'logger'

module Applitools::EyesLogger

  class NullLogger
    attr_accessor :level

    def info(msg)
      # do nothing
    end
    def debug(msg)
      #do nothing
    end
  end

  NULL_LOGGER = NullLogger.new

  @@log_handler = NULL_LOGGER

  def self.log_handler=(log_handler)
    if !log_handler.respond_to?(:info) || !log_handler.respond_to?(:debug)
      raise Applitools::EyesError.new('log handler must respond to "info" and "debug"!')
    end
    @@log_handler = log_handler
  end

  def self.info(msg)
    @@log_handler.info(msg)
  end

  def self.debug(msg)
    @@log_handler.debug(msg)
  end

  def self.open
    if @@log_handler.respond_to?(:open)
      @@log_handler.open
    end
  end

  def self.close
    if @@log_handler.respond_to?(:close)
      @@log_handler.close
    end
  end

end
