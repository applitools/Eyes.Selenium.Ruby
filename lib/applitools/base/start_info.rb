require 'applitools/core/session_start_info'
module Applitools::Base
  class StartInfo < Applitools::Core::SessionStartInfo
    def initialize(agent_id, app_id_or_name, scenario_id_or_name, batch_info, env_name, environment, match_level,
                   ver_id = nil, branch_name = nil, parent_branch_name = nil)
      super agent_id: agent_id, app_id_or_name: app_id_or_name, scenario_id_or_name: scenario_id_or_name,
            batch_info: batch_info, env_name: env_name, environment: environment, match_level: match_level,
            ver_id: ver_id, branch_name: branch_name, parent_branch_name: parent_branch_name
    end
  end
end
