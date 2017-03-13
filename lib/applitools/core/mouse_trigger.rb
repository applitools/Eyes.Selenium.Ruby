require 'applitools/core/trigger'
module Applitools::Core
  class MouseTrigger < Trigger
    TRIGGER_TYPE = :Mouse

    ##
    # A hash contains available mouse actions: +:click+, +:right_click+, +:double_click+, +:move+, +:down+, +:up+

    MOUSE_ACTION = {
      click: 'Click',
      right_click: 'RightClick',
      double_click: 'DoubleClick',
      move: 'Move',
      down: 'Down',
      up: 'Up'
    }.freeze

    attr_reader :mouse_action, :control, :location

    def initialize(mouse_action, control, location)
      @mouse_action = mouse_action
      @control = control
      @location = location
    end

    def to_hash
      {
        triggerType: trigger_type,
        mouseAction: MOUSE_ACTION[mouse_action],
        control: control.to_hash,
        location: location.to_hash
      }
    end

    def to_s
      "#{mouse_action} [#{control}] #{location.x}, #{location.y}"
    end
  end
end
