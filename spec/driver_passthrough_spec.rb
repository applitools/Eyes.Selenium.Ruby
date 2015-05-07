require 'spec_helper'

describe 'passthrough_methods' do

  before(:each) do |example|
    @eyes         = Applitools::Eyes.new
    @eyes.api_key = 'dummy_key'
    driver        = Selenium::WebDriver.for :phantomjs
    @driver       = @eyes.open(app_name:      'the-internet', test_name: example.metadata[:full_description],
                               viewport_size: { width: 800, height: 600 }, driver: driver)
    @driver.get STATIC_FILE
  end

  after(:each) do
    @eyes.close
    @driver.quit
  end

  it 'current_url' do
    url = @driver.current_url
    expect(url).to eq STATIC_FILE
  end

  describe 'find_element(s)' do
    context 'single element' do

      it 'explicit' do
        link = @driver.find_element(:css, 'a')
        expect(link).to_not be nil
        expect(link).to be_a Applitools::Selenium::Element
      end

      it 'by hash' do
        link = @driver.find_element(css: 'a')
        expect(link).to_not be nil
        expect(link).to be_a Applitools::Selenium::Element
      end

    end

    context 'all elements' do

      it 'explicit' do
        collection = @driver.find_elements(css: 'a')
        expect(collection).to_not be nil
        expect(collection[0]).to be_a Applitools::Selenium::Element
        expect(collection[1]).to be_a Applitools::Selenium::Element
      end

      it 'by hash' do
        collection = @driver.find_elements(css: 'a')
        expect(collection).to_not be nil
        expect(collection[0]).to be_a Applitools::Selenium::Element
        expect(collection[1]).to be_a Applitools::Selenium::Element
      end
    end
  end
end
