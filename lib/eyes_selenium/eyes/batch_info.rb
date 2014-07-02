require 'securerandom'

class Applitools::BatchInfo
  attr_accessor :id
  attr_reader :name, :started_at
  def initialize(name=nil, started_at = Time.now)
    @name = name
    @started_at = started_at
    @id = SecureRandom.uuid
  end

  def to_hash
    {
      name: name,
      id: id,
      startedAt: started_at.iso8601
    }
  end
end
