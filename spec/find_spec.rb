require 'eyes_selenium'

describe 'find_element(s)' do

  before(:each) do |example|
    @eyes = Applitools::Eyes.new
    @eyes.api_key = ENV['APPLITOOLS_ACCESS_KEY']
    driver = Selenium::WebDriver.for :firefox
    @driver = @eyes.open(app_name: 'the-internet', test_name: example.metadata[:full_description],
          viewport_size: {width: 800, height: 600}, driver: driver)
    @driver.get 'http://the-internet.herokuapp.com'
  end

  after(:each) do
    @eyes.close
    @driver.quit
  end

  context 'single element' do

    it 'explicit' do
      link = @driver.find_element(:css, 'a')
      expect(link).to_not be nil
      expect(link).to be_a Applitools::Element
    end

    it 'by hash' do
      link = @driver.find_element(css: 'a')
      expect(link).to_not be nil
      expect(link).to be_a Applitools::Element
    end

  end

  context 'all elements' do

    it 'explicit' do
      collection = @driver.find_elements(css: 'a')
      expect(collection).to_not be nil
      expect(collection[0]).to be_a Applitools::Element
      expect(collection[1]).to be_a Applitools::Element
    end

    it 'by hash' do
      collection = @driver.find_elements(css: 'a')
      expect(collection).to_not be nil
      expect(collection[0]).to be_a Applitools::Element
      expect(collection[1]).to be_a Applitools::Element
    end

  end

end
