module Applitools::Selenium
  class FrameChain
    include Enumerable

    def initialize(options = {})
      @frames = []
      @frames = options[:other].to_a if options[:other].is_a? self.class
    end

    def each(*args, &block)
      return @frames.collect unless block_given?
      @frames.each *args, &block
    end

    def same_frame_chain?(other)
      return false unless length == other.length
      all? {|my_elem| my_elem.id == other.next.id }
    end

    def push(frame)
      raise 'frame must be instance of Applitools::Selenium::Frame!' \
        " (passed #{frame.class})" unless frame.is_a? Applitools::Selenium::Frame
      @frames.push frame
    end

    def pop
      @frames.pop
    end

    def clear
      @frames = []
    end

    def current_frame_offset
      reduce(Applitools::Base::Point.new 0, 0) do |result, frame|
        result.offset frame.location
      end
    end

    def default_content_scroll_position
      raise NoFramesException.new 'No frames!' if @frames.empty?
      result = @frames.first.parent_scroll_position
      Applitools::Base::Point.new result.x, result.y
    end

    def current_frame_size
      @frames.last.size
    end

    class NoFramesException < Exception; end
  end
end