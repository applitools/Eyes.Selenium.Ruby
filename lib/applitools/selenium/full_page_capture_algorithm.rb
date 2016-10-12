module Applitools::Selenium
  class FullPageCaptureAlgorithm

    def get_stiched_region(*args)
      Applitools::Core::Screenshot.new ChunkyPNG::Image.new(2048, 2048).to_datastream.to_blob
    end
  end
end