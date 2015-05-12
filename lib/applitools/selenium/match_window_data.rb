class Applitools::Selenium::MatchWindowData
  attr_reader :user_inputs, :app_output, :tag, :ignore_mismatch, :screenshot

  def initialize(app_output, user_inputs = [], tag, ignore_mismatch, screenshot)
    @user_inputs = user_inputs
    @app_output = app_output
    @tag = tag
    @ignore_mismatch = ignore_mismatch
    @screenshot = screenshot
  end

  # IMPORTANT This method returns a hash WITHOUT the screenshot property. This is on purspose! The screenshot should
  # not be included as part of the json.
  def to_hash
    {
      userInputs: user_inputs.map(&:to_hash),
      appOutput: Hash[app_output.each_pair.to_a],
      tag: @tag,
      ignoreMismatch: @ignore_mismatch
    }
  end
end
