require 'logger'
require 'forwardable'

module Applitools::EyesLogger
  class NullLogger < Logger
    def initialize(*_args) end

    def add(*_args, &_block) end
  end

  extend Forwardable
  extend self

  MANDATORY_METHODS = [:debug, :info, :close].freeze
  OPTIONAL_METHODS = [:warn, :error, :fatal].freeze

  def_delegators :@log_handler, *MANDATORY_METHODS

  @log_handler = NullLogger.new

  def log_handler=(log_handler)
    raise Applitools::EyesError.new('log_handler must implement Logger!') unless valid?(log_handler)

    @log_handler = log_handler
  end

  def log_handler
    @log_handler
  end

  def logger
    self
  end

  OPTIONAL_METHODS.each do |method|
    define_singleton_method(method) do |msg|
      @log_handler.respond_to?(method) ? @log_handler.send(method, msg) : @log_handler.info(msg)
    end
  end

  private

  def valid?(log_handler)
    MANDATORY_METHODS.all? { |method| log_handler.respond_to?(method) }
  end
end
