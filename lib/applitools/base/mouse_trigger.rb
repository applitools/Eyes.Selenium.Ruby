class Applitools::Base::MouseTrigger
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
      triggetType: 'Mouse',
      mouseAction: MOUSE_ACTION[mouse_action],
      control: control.to_hash,
      location: Hash[location.each_pair.to_a]
    }
  end

  def to_s
    "#{mouse_action} [#{control}] #{location.x}, #{location.y}"
  end
end
