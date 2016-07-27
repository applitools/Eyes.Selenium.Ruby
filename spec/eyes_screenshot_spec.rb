require 'spec_helper'

RSpec.describe Applitools::Core::EyesScreenshot do
  it_should_behave_like "responds to method", [
      :intersected_region,
      :location_in_screenshot,
      :sub_screenshot,
      :image
  ]

end