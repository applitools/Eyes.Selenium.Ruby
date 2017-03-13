module Applitools::Core
  # Provides 'cut' method which is used to cut screen shots
  class FixedCutProvider
    # Creates a FixedCutProvider instance
    # @param [Applitools::Core::Region] crop_region Outside space of the region will be cropped
    # @param [Integer] header A top field to crop
    # @param [Integer] left A left field to crop
    # @param [Integer] right A right field to crop
    # @param [Integer] footer A bottom field to crop
    # @example Creates cut provider by a Region
    #   Applitools::Core::FixedCutProvider.new Applitools::Core::Region.new(20,20, 300, 300)
    # @example Creates cut provider by a set of fields
    #   Applitools::Core::FixedCutProvider.new 20, 20, 300, 300
    def initialize(*args)
      self.region = nil
      self.left = 0
      self.header = 0
      self.right = 0
      self.footer = 0
      case args.length
      when 1
        initialize_by_rectangle(args[0])
      when 4
        initialize_by_fields(*args)
      end
    end

    def cut(image)
      Applitools::Utils::ImageUtils.cut! image, crop_region(image)
    end

    private

    attr_accessor :header, :footer, :left, :right, :region

    def initialize_by_rectangle(region)
      unless region.is_a? Applitools::Core::Region
        raise Applitools::EyesIllegalArgument.new 'Applitools::Core::Region expected as argument ' /
          " (#{region.class} is passed)."
      end
      self.region = region
    end

    def initialize_by_fields(header, footer, left, right)
      self.header = header
      self.footer = footer
      self.left = left
      self.right = right
    end

    def crop_region(image)
      current_height = image.height
      current_width = image.width
      if region.nil?
        Applitools::Core::Region.new(left, header, current_width - left - right, current_height - header - footer)
      else
        region.dup
      end
    end
  end
end
