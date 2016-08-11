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

  end
end