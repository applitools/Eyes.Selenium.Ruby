module Applitools::Core
  class MatchWindowData
    attr_accessor :app_output, :user_inputs, :tag, :options, :ignore_mistmatch

    def initialize(user_inputs, app_output, tag, ignore_mistmatch, options={})
      self.user_inputs = user_inputs
      self.app_output = app_output
      self.tag = tag
      self.ignore_mistmatch = ignore_mistmatch
      self.options = options
    end

    def screenshot
      app_output.screenshot.image.to_blob
    end

    alias appOutput app_output
    alias userInputs user_inputs
    alias ignoreMistmatch ignore_mistmatch

    def to_hash
      %i(userInputs appOutput tag ignoreMistmatch).map do |field|
        result = send(field)
        result = result.to_hash if result.respond_to? :to_hash
        [field, result] if [String, Symbol, Hash, Array].include? result.class
      end.compact.to_h
    end

  end
end