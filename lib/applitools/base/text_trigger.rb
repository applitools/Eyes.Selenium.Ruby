module Applitools::Base
  class TextTrigger
    attr_reader :text, :control

    def initialize(text, control)
      @text = text
      @control = control
    end

    def to_hash
      {
        trigget_type: 'Text',
        text: text,
        control: control.to_hash
      }
    end

    def to_s
      "Text [#{@control}] #{@text}"
    end
  end
end
