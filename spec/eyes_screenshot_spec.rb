require 'spec_helper'

RSpec.describe Applitools::Core::EyesScreenshot do
  describe 'initializer' do
    it 'checks if screenshot is passed' do
      expect { Applitools::Core::EyesScreenshot.new(:not_a_screennshot) }.to raise_error(
        Applitools::EyesIllegalArgument
      )
    end
  end

  describe 'methods:' do
    subject do
      Applitools::Core::EyesScreenshot.new(
        Applitools::Core::Screenshot.new(ChunkyPNG::Image.new(1, 1, ChunkyPNG::Color::TRANSPARENT).to_blob)
      )
    end

    it_should_behave_like 'has abstract method', [
      :sub_screenshot,
      :convert_location,
      :location_in_screenshot,
      :intersected_region
    ]

    it_should_behave_like 'responds to method', [
      :intersected_region,
      :location_in_screenshot,
      :sub_screenshot,
      :image
    ]
  end
end
