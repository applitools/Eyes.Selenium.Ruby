require 'pry'
module Applitools::ChunkyPNG
  module Resampling
    INTERPOLATION_DATA = Struct.new("InterpolationData", :index, :x0,:x1,:x2,:x3, :t)

    def resample_bicubic!(dst_width, dst_height)
      points = bicubic_x_points(dst_width)
      pixels = Array.new(points.size)

      points.each do |interpolation_data|
        pixels[interpolation_data[:index]] = interpolate_cubic(interpolation_data)
      end
      replace_canvas!(dst_width, height, pixels)

      points = bicubic_y_points(dst_height)
      pixels = Array.new(points.size)

      points.each do |interpolation_data|
        pixels[interpolation_data[:index]] = interpolate_cubic(interpolation_data)
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

    def interpolate_cubic(data)
      result = {}
      threads = {}
      t = data[:t]
      [:r, :g, :b, :a].each do |chan|
        threads[chan] = Thread.new do
          c0 = ChunkyPNG::Color.send(chan, data[:x0])
          c1 = ChunkyPNG::Color.send(chan, data[:x1])
          c2 = ChunkyPNG::Color.send(chan, data[:x2])
          c3 = ChunkyPNG::Color.send(chan, data[:x3])

          # a = -0.5*c0 + 1.5*c1 - 1.5*c2 + 0.5*c3
          # b = c0 - 2.5*c1 + 2*c2 - 0.5*c3
          # c = 0.5*c2 - 0.5*c0
          # d = c1

          a = -ChunkyPNG::Color.int8_mult(c0, 128)+ChunkyPNG::Color.int8_mult(c1, 384)-
              ChunkyPNG::Color.int8_mult(c2, 384)+ChunkyPNG::Color.int8_mult(c3, 128)
          b = c0 - ChunkyPNG::Color.int8_mult(c1, 640) + (c2 << 1) - ChunkyPNG::Color.int8_mult(c3, 128)
          c = ChunkyPNG::Color.int8_mult(c2, 128) - ChunkyPNG::Color.int8_mult(c0, 128)
          d = c1

          # a = c3 - c2 - c0 + c1
          # b = c0 - c1 - a
          # c = c2 - c0
          # d = c1

          # puts "#{a} #{b} #{c} #{d} #{t}=> #{(a*t**3 + b*t**2 + c*t + d)}"
          [0,[255, (a*t**3 + b*t**2 + c*t + d).to_i].min].max
          # result[chan] = 255
        end
      end
      ChunkyPNG::Color.rgba(threads[:r].value, threads[:g].value, threads[:b].value, threads[:a].value)
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