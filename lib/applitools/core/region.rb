module Applitools::Core
  class Region
    attr_accessor :left, :top, :width, :height
    alias x left
    alias y top

    class << self
      def from_location_size(location, size)
        new location.x, location.y, size.width, size.height
      end
    end

    def initialize(left, top, width, height)
      @left = left.round
      @top = top.round
      @width = width.round
      @height = height.round
    end

    EMPTY = Region.new(0, 0, 0, 0)

    def make_empty
      @left = EMPTY.left
      @top = EMPTY.top
      @width = EMPTY.width
      @height = EMPTY.height
    end

    def empty?
      @left == EMPTY.left && @top == EMPTY.top && @width == EMPTY.width && @height == EMPTY.height
    end

    def size
      Applitools::Core::RectangleSize.new width, height
    end

    def location
      Location.new left, top
    end

    def location=(other_location)
      self.left = other_location.left
      self.top = other_location.top
    end

    def right
      left + width
    end

    def bottom
      top + height
    end

    def intersecting?(other)
      ((left <= other.left && other.left <= right) || (other.left <= left && left <= other.right)) &&
        ((top <= other.top && other.top <= bottom) || (other.top <= top && top <= other.bottom))
    end

    def intersect(other)
      unless intersecting?(other)
        make_empty

        return
      end

      i_left = left >= other.left ? left : other.left
      i_right = right <= other.right ? right : other.right
      i_top = top >= other.top ? top : other.top
      i_bottom = bottom <= other.bottom ? bottom : other.bottom

      @left = i_left
      @top = i_top
      @width = i_right - i_left
      @height = i_bottom - i_top
    end

    def contains?(other_left, other_top)
      other_left >= left && other_left <= right && other_top >= top && other_top <= bottom
    end

    def middle_offset
      mid_x = width / 2
      mid_y = height / 2
      Applitools::Core::Location.for(mid_x.round, mid_y.round)
    end

    def sub_regions(subregion_size, is_fixed_size = false)
      return self.class.sub_regions_with_fixed_size self, subregion_size if is_fixed_size
      self.class.sub_regions_with_varying_size self, subregion_size
    end

    def to_hash
      {
        left: left,
        top: top,
        height: height,
        width: width
      }
    end

    def to_s
      "(#{left}, #{top}), #{width} x #{height}"
    end

    def size_equals?(region)
      width == region.width && height == region.height
    end

    class << self
      def sub_regions_with_fixed_size(container_region, sub_region)
        Applitools::Core::ArgumentGuard.not_nil container_region, 'container_region'
        Applitools::Core::ArgumentGuard.not_nil sub_region, 'sub_region'

        Applitools::Core::ArgumentGuard.greater_than_zero(sub_region.width, 'sub_region.width')
        Applitools::Core::ArgumentGuard.greater_than_zero(sub_region.height, 'sub_region.height')

        sub_region_width = sub_region.width
        sub_region_height = sub_region.height

        # Normalizing.
        sub_region_width = container_region.width if sub_region_width > container_region.width
        sub_region_height = container_region.height if sub_region_height > container_region.height

        if sub_region_width == container_region.width && sub_region_height == container_region.height
          return Enumerator(1) do |y|
            y << sub_region
          end
        end

        current_top = container_region.top
        bottom = container_region.top + container_region.height - 1
        right = container_region.left + container_region.width - 1
        Enumerator.new do |y|
          while current_top <= bottom
            current_top = (bottom - sub_region_height) + 1 if current_top + sub_region_height > bottom
            current_left = container_region.left
            while current_left <= right
              current_left = (rught - sub_region_width) + 1 if current_left + sub_region_width > right
              y << new(current_left, current_top, sub_region_width, sub_region_height)
              current_left += sub_region_width
            end
            current_top += sub_region_height
          end
        end
      end

      def sub_regions_with_varying_size(container_region, sub_region)
        Applitools::Core::ArgumentGuard.not_nil container_region, 'container_region'
        Applitools::Core::ArgumentGuard.not_nil sub_region, 'sub_region'

        Applitools::Core::ArgumentGuard.greater_than_zero(sub_region.width, 'sub_region.width')
        Applitools::Core::ArgumentGuard.greater_than_zero(sub_region.height, 'sub_region.height')

        current_top = container_region.top
        bottom = container_region.top + container_region.height
        right = container_region.left + container_region.width

        Enumerator.new do |y|
          while current_top < bottom
            current_bottom = current_top + sub_region.height
            current_bottom = bottom if current_bottom > bottom
            current_left = container_region.left
            while current_left < right
              current_right = current_left + sub_region.width
              current_right = right if current_right > right

              current_height = current_bottom - current_top
              current_width = current_right - current_left

              y << new(current_left, current_top, current_width, current_height)

              current_left += sub_region.width
            end
            current_top += sub_region.height
          end
        end
      end
    end
  end
end
