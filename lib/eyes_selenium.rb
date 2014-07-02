require 'json'
require 'eyes_selenium/eyes_logger'
require 'json'
module Applitools
  include EyesLogger
  class EyesError < StandardError; end
  class EyesAbort < EyesError; end

  class TestFailedError < StandardError
    attr_accessor :test_results
    def initialize(message, test_results=nil)
      super(message)
      @test_results = test_results
    end
  end
  class NewTestError < TestFailedError; end

  require 'eyes_selenium/utils'
  require 'eyes_selenium/version'
  require 'eyes_selenium/eyes/agent_connector'
  require 'eyes_selenium/eyes/batch_info'
  require 'eyes_selenium/eyes/dimension'
  require 'eyes_selenium/eyes/driver'
  require 'eyes_selenium/eyes/element'
  require 'eyes_selenium/eyes/environment'
  require 'eyes_selenium/eyes/eyes'
  require 'eyes_selenium/eyes/eyes_keyboard'
  require 'eyes_selenium/eyes/eyes_mouse'
  require 'eyes_selenium/eyes/failure_reports'
  require 'eyes_selenium/eyes/match_level'
  require 'eyes_selenium/eyes/match_window_data'
  require 'eyes_selenium/eyes/match_window_task'
  require 'eyes_selenium/eyes/mouse_trigger'
  require 'eyes_selenium/eyes/region'
  require 'eyes_selenium/eyes/screenshot_taker'
  require 'eyes_selenium/eyes/session'
  require 'eyes_selenium/eyes/start_info'
  require 'eyes_selenium/eyes/test_results'
  require 'eyes_selenium/eyes/text_trigger'
  require 'eyes_selenium/eyes/viewport_size'
end
