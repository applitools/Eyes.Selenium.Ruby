require 'pry'
module Applitools::ChunkyPNG
  module Resampling

    INTERPOLATION_DATA = Struct.new("InterpolationData", :index, :x0,:x1,:x2,:x3, :t)
    MERGE_DATA = Struct.new("MergeData", :index, :pixels)

    def resample_bicubic!(dst_width, dst_height)
      w_m = [1, width / dst_width].max
      h_m = [1, height / dst_height].max

      dst_width2 = dst_width*w_m
      dst_height2 = dst_height*h_m

      points = bicubic_x_points(dst_width2)
      pixels = Array.new(points.size)

      points.each do |interpolation_data|
        pixels[interpolation_data[:index]] = interpolate_cubic(interpolation_data)
      end
      replace_canvas!(dst_width2, height, pixels)

      points = bicubic_y_points(dst_height2)
      pixels = Array.new(points.size)

      points.each do |interpolation_data|
        pixels[interpolation_data[:index]] = interpolate_cubic(interpolation_data)
      end
      replace_canvas!(dst_width2,dst_height2, pixels)

      return self unless w_m*h_m > 1

      points = scale_points(dst_width, dst_height, w_m, h_m)
      pixels = Array.new(points.size)

      points.each do |merge_data|
        pixels[merge_data[:index]] = merge_pixels(merge_data[:pixels], w_m*h_m)
      end

      replace_canvas!(dst_width,dst_height, pixels)
    end

    def resample_bicubic(new_width, new_height)
      dup.resample_bicubic!(new_width, new_height)
    end

    def bicubic_x_points(dst_width)
      bicubic_points(width, dst_width, false)
    end

    def bicubic_y_points(dst_height)
      bicubic_points(height, dst_height, true)
    end

    def bicubic_points(src_dimension, dst_dimension, direction)
      step = (src_dimension-1).to_f / dst_dimension
      y_bounds = direction ? width : height
      pixels_size = y_bounds*dst_dimension
      Enumerator.new(pixels_size) do |enum|
        for y in 0..y_bounds-1
          line = direction ? column(y) : row(y)
          index_y = dst_dimension*y
          for x in 0..dst_dimension-1
            pos = (x*step).to_i
            t = x*step - pos
            x0 = pos > 0 ? line[pos-1] : imaginable_point(line[pos], line[pos+1])
            x1 = line[pos]
            x2 = line[pos+1]
            x3 = pos < src_dimension - 2 ? line[pos+2] : imaginable_point(line[pos+1], line[pos])
            index = direction ? y_bounds*x + y : index_y + x
            enum << INTERPOLATION_DATA.new(index,x0,x1,x2,x3,t)
          end
        end
      end
    end

    def scale_points(dst_width, dst_height, w_m, h_m)
      Enumerator.new(dst_width*dst_height) do |enum|
        for i in 0..dst_height-1
          for j in 0..dst_width-1
            pixels_to_merge = []
            for y in 0..h_m-1
              y_pos = i*h_m + y
              for x in 0..w_m-1
                x_pos = j*w_m + x
                pixels_to_merge << get_pixel(x_pos, y_pos)
              end
            end
            index = i*dst_width + j
            enum << MERGE_DATA.new(index, pixels_to_merge)
          end
        end
      end
    end

    def merge_pixels(pixels, m)
      merged_data = pixels.inject({r: 0, g: 0, b: 0, a: 0, real_colors: 0}) do |result, pixel|
        unless ChunkyPNG::Color.fully_transparent?(pixel)
          result[:real_colors] += 1
          [:r,:g,:b].each do |ch|
            result[ch] += ChunkyPNG::Color.send(ch, pixel)
          end
        end
        result[:a] += ChunkyPNG::Color.a(pixel)
        result
      end

      r = merged_data[:real_colors] > 0 ? merged_data[:r] / merged_data[:real_colors] : 0
      g = merged_data[:real_colors] > 0 ? merged_data[:g] / merged_data[:real_colors] : 0
      b = merged_data[:real_colors] > 0 ? merged_data[:b] / merged_data[:real_colors] : 0
      a = merged_data[:a] / m

      ChunkyPNG::Color.rgba(r, g, b, a)
    end

    def interpolate_cubic(data)
      result = {}
      t = data[:t]
      [:r, :g, :b, :a].each do |chan|
        c0 = ChunkyPNG::Color.send(chan, data[:x0])
        c1 = ChunkyPNG::Color.send(chan, data[:x1])
        c2 = ChunkyPNG::Color.send(chan, data[:x2])
        c3 = ChunkyPNG::Color.send(chan, data[:x3])

        a = -0.5*c0 + 1.5*c1 - 1.5*c2 + 0.5*c3
        b = c0 - 2.5*c1 + 2*c2 - 0.5*c3
        c = 0.5*c2 - 0.5*c0
        d = c1

        result[chan] = [0,[255, (a*t**3 + b*t**2 + c*t + d).to_i].min].max
      end
      ChunkyPNG::Color.rgba(result[:r], result[:g], result[:b], result[:a])
    end

    def imaginable_point(point1, point2)
      r = [0, [255, ChunkyPNG::Color.r(point1) << 1].min - ChunkyPNG::Color.r(point2)].max
      g = [0, [255, ChunkyPNG::Color.g(point1) << 1].min - ChunkyPNG::Color.g(point2)].max
      b = [0, [255, ChunkyPNG::Color.b(point1) << 1].min - ChunkyPNG::Color.b(point2)].max
      a = [0, [255, ChunkyPNG::Color.a(point1) << 1].min - ChunkyPNG::Color.a(point2)].max
      ChunkyPNG::Color.rgba(r, g, b, a)
    end
  end
end