module Applitools::Core
  class Screenshot < Delegator
    extend Forwardable
    def_delegators :header, :width, :height

    def initialize(image)
      @datastream = ChunkyPNG::Datastream.from_string image
    end

    def to_blob
      @datastream.to_blob
    end

    def __getobj__
      restore
    end

    def header
      @datastream.header_chunk
    end

    def __setobj__(obj)
      @datastream = obj.to_datastream
      self
    end

    def method_missing(method, *args, &block)
      if method =~ /^.+!$/
        __setobj__ super
      else
        super
      end
    end

    def restore
      ChunkyPNG::Image.from_datastream @datastream
    end
  end
end