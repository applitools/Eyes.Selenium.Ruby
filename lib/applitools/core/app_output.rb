module Applitools::Core
  class AppOutput
    attr_reader :title, :screenshot64

    def initialize(title, screenshot64)
      @title = title
      @screenshot64 = screenshot64
    end

    def to_hash
      {
        title: title,
        screenshot64: ''
      }
    end
  end
end
