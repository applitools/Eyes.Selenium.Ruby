class Applitools::Selenium::Session
  attr_reader :eyes, :id, :url
  attr_accessor :new_session
  def initialize(session_id, session_url, new_session)
    @new_session = new_session
    @id = session_id
    @url = session_url
  end

  def new_session?
    self.new_session
  end
end

