module Applitools::Core
  class MatchResult
    attr_reader :response_hash
    attr_accessor :screenshot

    def initialize(response_hash)
      Applitools::Core::ArgumentGuard.hash response_hash, 'response hash', ['asExpected']
      @response_hash = response_hash
    end

    def as_expected?
      return response_hash['asExpected'] if [TrueClass, FalseClass].include? response_hash['asExpected'].class
      false
    end
  end
end
