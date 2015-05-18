module Applitools::Base
  class Environment
    attr_accessor :os, :hosting_app, :display_size, :inferred

    def initialize(os = nil, hosting_app = nil, display_size = nil, inferred = nil)
      @os = os
      @hosting_app = hosting_app
      @display_size = display_size
      @inferred = inferred
    end

    def to_hash
      {
        os: os,
        hostingApp: hosting_app,
        displaySize: display_size.to_hash,
        inferred: inferred
      }
    end
  end
end
