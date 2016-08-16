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

    def to_hash
      %i(user_inputs app_output tag ignore_mistmatch options).map do |field|
        [field, send(field)]
      end.to_h
    end

  end
end