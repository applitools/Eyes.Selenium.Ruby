module Applitools::Base
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
    end

    def passed?
      !is_new && !(mismatches > 0) && !(missing > 0)
    end
    alias is_passed passed?

    def to_s
      is_new_str = ''
      is_new_str = is_new ? 'New test' : 'Existing test' unless is_new.nil?

      "#{is_new_str} [ steps: #{steps}, matches: #{matches}, mismatches: #{mismatches}, missing: #{missing} ], "\
        "URL: #{url}"
    end
  end
end
