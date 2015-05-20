require 'spec_helper'

describe 'passthrough methods' do
  let(:static_file) { "file://#{File.dirname(__FILE__)}/fixtures/static_test_file.html" }
  let(:eyes) { Applitools::Eyes.new }
  let(:web_driver) { Selenium::WebDriver.for :phantomjs }

  before do |example|
    eyes.api_key = 'dummy_key'

    @driver = eyes.open(app_name: 'Specs', test_name: example.metadata[:full_description],
      viewport_size: {width: 800, height: 600}, driver: web_driver)
    @driver.get static_file
  end

  after do
    eyes.close

    @driver.quit
  end

  it 'current_url' do
    url = @driver.current_url
    expect(url).to eq(static_file)
  end

  describe 'find_element(s)' do
    context 'single element' do
      it 'explicit' do
        link = @driver.find_element(:css, 'a')
        expect(link).not_to be_nil
        expect(link).to be_a(Applitools::Selenium::Element)
      end

      it 'by hash' do
        link = @driver.find_element(css: 'a')
        expect(link).not_to be_nil
        expect(link).to be_a(Applitools::Selenium::Element)
      end
    end

    context 'all elements' do
      it 'explicit' do
        collection = @driver.find_elements(css: 'a')
        expect(collection).not_to be_nil
        expect(collection[0]).to be_a(Applitools::Selenium::Element)
        expect(collection[1]).to be_a(Applitools::Selenium::Element)
      end

      it 'by hash' do
        collection = @driver.find_elements(css: 'a')
        expect(collection).not_to be_nil
        expect(collection[0]).to be_a(Applitools::Selenium::Element)
        expect(collection[1]).to be_a(Applitools::Selenium::Element)
      end
    end
  end
end
