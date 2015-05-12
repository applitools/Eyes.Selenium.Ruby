require 'logger'
require 'forwardable'

module Applitools::EyesLogger
  class NullLogger < Logger
    def initialize(*args)
    end

    def add(*args, &block)
    end
  end

  extend Forwardable
  extend self

  def_delegators :@@log_handler, :debug, :info, :warn, :error, :fatal, :open, :close

  @@log_handler = NullLogger.new

  def log_handler=(log_handler)
    raise Applitools::EyesError.new('log_handler must implement Logger!') unless log_handler.is_a?(Logger)

    @@log_handler = log_handler
  end
end
