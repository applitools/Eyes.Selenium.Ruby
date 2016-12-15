module Applitools::Core
  class Session
    attr_reader :id, :url

    def initialize(session_id, session_url, new_session)
      @id = session_id
      @url = session_url
      @new_session = new_session
    end

    def new_session?
      @new_session
    end
  end
end
