module Applitools::Base
  class Session
    attr_reader :id, :url, :new_session
    alias new_session? new_session

    def initialize(session_id, session_url, new_session)
      @id = session_id
      @url = session_url
      @new_session = new_session
    end
  end
end
