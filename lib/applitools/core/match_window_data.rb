module Applitools::Core
  class MatchWindowData
    attr_accessor :app_output, :user_inputs, :tag, :options, :ignore_mismatch

    def initialize(user_inputs, app_output, tag, ignore_mismatch, options = {})
      self.user_inputs = user_inputs
      self.app_output = app_output
      self.tag = tag
      self.ignore_mismatch = ignore_mismatch
      self.options = options
    end

    def screenshot
      app_output.screenshot.image.to_blob
    end

    alias appOutput app_output
    alias userInputs user_inputs
    alias ignoreMismatch ignore_mismatch

    def to_hash
      %i(userInputs appOutput tag ignoreMismatch).map do |field|
        result = send(field)
        result = result.to_hash if result.respond_to? :to_hash
        [field, result] if [String, Symbol, Hash, Array, FalseClass, TrueClass].include? result.class
      end.compact.to_h
    end

    def to_s
      to_hash
    end
  end
end
