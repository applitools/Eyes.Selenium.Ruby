module Applitools::ChunkyPNG
  module Resampling
    def resample_bicubic!(dst_width, dst_height)
      w_m = [1, width / dst_width].max
      h_m = [1, height / dst_height].max

      dst_width2 = dst_width * w_m
      dst_height2 = dst_height * h_m

      points = bicubic_x_points(dst_width2)
      pixels = Array.new(points.size)

      points.each do |interpolation_data|
        pixels[interpolation_data[0]] = interpolate_cubic(interpolation_data)
      end
      replace_canvas!(dst_width2, height, pixels)

      points = bicubic_y_points(dst_height2)
      pixels = Array.new(points.size)

      points.each do |interpolation_data|
        pixels[interpolation_data[0]] = interpolate_cubic(interpolation_data)
      end
      replace_canvas!(dst_width2, dst_height2, pixels)

      return self unless w_m * h_m > 1

      points = scale_points(dst_width, dst_height, w_m, h_m)
      pixels = Array.new(points.size)

      points.each do |merge_data|
        pixels[merge_data[0]] = merge_pixels(merge_data)
      end

      replace_canvas!(dst_width, dst_height, pixels)
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

    def bicubic_points(src_dimension, dst_dimension, direction, y_start_position = 0)
      step = (src_dimension - 1).to_f / dst_dimension
      y_bounds = direction ? width : height
      raise ArgumentError.new 'Start position value is invalid!' unless y_start_position < y_bounds
      pixels_size = (y_bounds - y_start_position) * dst_dimension

      steps = Array.new(dst_dimension)
      residues = Array.new(dst_dimension)

      (0..dst_dimension - 1).each do |i|
        steps[i] = (i * step).to_i
        residues[i] = i * step - steps[i]
      end
      Enumerator.new(pixels_size) do |enum|
        (y_start_position..y_bounds - 1).each do |y|
          line = (direction ? column(y) : row(y))

          line_with_bounds = [imaginable_point(line[0], line[1])] + line + [
            imaginable_point(line[src_dimension - 2], line[src_dimension - 3]),
            imaginable_point(line[src_dimension - 1], line[src_dimension - 2])
          ]

          index_y = dst_dimension * y
          (0..dst_dimension - 1).each do |x|
            index = direction ? y_bounds * x + y : index_y + x
            enum << ([index, residues[x]] + line_with_bounds.last(src_dimension + 3 - steps[x]).first(4))
          end
        end
      end
    end

    def scale_points(dst_width, dst_height, w_m, h_m)
      Enumerator.new(dst_width * dst_height) do |enum|
        (0..dst_height - 1).each do |i|
          (0..dst_width - 1).each do |j|
            pixels_to_merge = []
            (0..h_m - 1).each do |y|
              y_pos = i * h_m + y
              (0..w_m - 1).each do |x|
                x_pos = j * w_m + x
                pixels_to_merge << get_pixel(x_pos, y_pos)
              end
            end
            index = i * dst_width + j
            enum << ([index] + pixels_to_merge)
          end
        end
      end
    end

    def merge_pixels(merge_data)
      pixels = merge_data[1..merge_data.size]
      merged_data = pixels.each_with_object(r: 0, g: 0, b: 0, a: 0, real_colors: 0) do |pixel, result|
        unless ChunkyPNG::Color.fully_transparent?(pixel)
          result[:real_colors] += 1
          [:r, :g, :b].each do |ch|
            result[ch] += ChunkyPNG::Color.send(ch, pixel)
          end
        end
        result[:a] += ChunkyPNG::Color.a(pixel)
        result
      end

      r = merged_data[:real_colors] > 0 ? merged_data[:r] / merged_data[:real_colors] : 0
      g = merged_data[:real_colors] > 0 ? merged_data[:g] / merged_data[:real_colors] : 0
      b = merged_data[:real_colors] > 0 ? merged_data[:b] / merged_data[:real_colors] : 0
      a = merged_data[:a] / pixels.size

      ChunkyPNG::Color.rgba(r, g, b, a)
    end

    def interpolate_cubic(data)
      result = {}
      t = data[1]
      [:r, :g, :b, :a].each do |chan|
        c0 = ChunkyPNG::Color.send(chan, data[2])
        c1 = ChunkyPNG::Color.send(chan, data[3])
        c2 = ChunkyPNG::Color.send(chan, data[4])
        c3 = ChunkyPNG::Color.send(chan, data[5])

        a = -0.5 * c0 + 1.5 * c1 - 1.5 * c2 + 0.5 * c3
        b = c0 - 2.5 * c1 + 2 * c2 - 0.5 * c3
        c = 0.5 * c2 - 0.5 * c0
        d = c1

        result[chan] = [0, [255, (a * t**3 + b * t**2 + c * t + d).to_i].min].max
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
