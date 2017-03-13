require 'oily_png'
require_relative 'chunky_png/resampling'
require 'applitools/resampling_fast'

ChunkyPNG::Canvas.class_eval do
  include Applitools::ChunkyPNG::Resampling
  include Applitools::ResamplingFast
end
