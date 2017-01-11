require_relative 'chunky_png/resampling'

ChunkyPNG::Canvas.class_eval do
  include Applitools::ChunkyPNG::Resampling
end