require 'yaml'

module Applitools::Core
  class TestResults
    attr_accessor :is_new, :url
    attr_reader :steps, :matches, :mismatches, :missing

    def initialize(results = {})
      @steps = results.fetch('steps', 0)
      @matches = results.fetch('matches', 0)
      @mismatches = results.fetch('mismatches', 0)
      @missing = results.fetch('missing', 0)
      @is_new = nil
      @url = nil
      @original_results = results
    end

    def passed?
      return !(mismatches > 0) && !(missing > 0) unless new?
      false
    end

    def failed?
      return (mismatches > 0) || (missing > 0) unless new?
      false
    end

    def new?
      is_new
    end

    def ==(other)
      if other.is_a? self.class
        result = true
        %i(is_new url steps matches mismatches missing).each do |field|
          result &&= send(field) == other.send(field)
        end
        return result if result
      end
      false
    end

    alias is_passed passed?

    def to_s(advanced = false)
      is_new_str = ''
      is_new_str = is_new ? 'New test' : 'Existing test' unless is_new.nil?

      return @original_results.to_yaml if advanced

      "#{is_new_str} [ steps: #{steps}, matches: #{matches}, mismatches: #{mismatches}, missing: #{missing} ], " \
        "URL: #{url}"
    end
  end
end
