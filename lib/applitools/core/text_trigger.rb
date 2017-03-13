require 'applitools/core/trigger'
module Applitools::Core
  class TextTrigger < Trigger
    TRIGGER_TYPE = :Text
    attr_reader :text, :control

    def initialize(text, control)
      @text = text
      @control = control
    end

    def to_hash
      {
        triggerType: trigger_type,
        text: text,
        control: control.to_hash
      }
    end

    def to_s
      "Text [#{@control}] #{@text}"
    end
  end
end
