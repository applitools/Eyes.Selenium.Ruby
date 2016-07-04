module Applitools::Selenium
  class MatchWindowData
    attr_reader :user_inputs, :app_output, :tag, :ignore_mismatch, :screenshot

    def initialize(app_output, tag, ignore_mismatch, screenshot, user_inputs = [])
      @user_inputs = user_inputs
      @app_output = app_output
      @tag = tag
      @ignore_mismatch = ignore_mismatch
      @screenshot = screenshot
    end

    # IMPORTANT This method returns a hash WITHOUT the screenshot property. This is on purpose! The screenshot should
    # not be included as part of the json.
    def to_hash
      {
        user_inputs: user_inputs.map(&:to_hash),
        app_output: Hash[app_output.each_pair.to_a],
        tag: @tag,
        ignore_mismatch: @ignore_mismatch
      }
    end
  end
end
