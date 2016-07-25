module Applitools::Core
  class AppEnvironment
    attr_accessor :os, :hosting_app, :display_size, :inferred_environment

    # def initialize(os = nil, hosting_app = nil, display_size = nil, inferred = nil)
    #   @os = os
    #   @hosting_app = hosting_app
    #   @display_size = display_size
    #   @inferred = inferred
    # end

    def initialize(options = {})
      @os = options[:os]
      @hosting_app = options[:hosting_app]
      @display_size = options[:display_size]
      @inferred = options[:inferred]
    end

    def to_hash
      {
          os: @os,
          hosting_app: @hosting_app,
          display_size: @display_size.to_hash,
          inferred: @inferred
      }
    end
  end
end