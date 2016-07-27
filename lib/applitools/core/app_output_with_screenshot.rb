module Applitools::Core
  class AppOutputWithScreenshot
    attr_reader :app_output, :screenshot

    def initialize(app_output, screenshot)
      raise Applitools::EyesIllegalArgument.new 'app_output is not kind of Applitools::Core::AppOutput' unless app_output.kind_of? Applitools::Core::AppOutput
      raise Applitools::EyesIllegalArgument.new 'screenshot is not kind of Applitools::Core::EyesScreenshot' unless screenshot.kind_of? Applitools::Core::EyesScreenshot
      @app_output = app_output
      @screenshot = screenshot
    end
  end
end