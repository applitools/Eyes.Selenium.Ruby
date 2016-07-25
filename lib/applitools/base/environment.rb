require 'applitools/core/app_environment'
module Applitools::Base
  class Environment < Applitools::Core::AppEnvironment
    def initialize(os = nil, hosting_app = nil, display_size = nil, inferred = nil)
      super os: os, hosting_app: hosting_app, display_size: display_size, inferred: inferred
    end
  end
end
