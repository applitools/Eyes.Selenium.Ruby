require 'securerandom'
module Applitools::Core
  class BatchInfo
    def initialize(name = nil, started_at = Time.now)
      @name = name
      @started_at = started_at
      @id = SecureRandom.uuid
    end

    def to_hash
      {
        id: @id,
        name: @name,
        started_at: @started_at.iso8601
      }
    end
  end
end
