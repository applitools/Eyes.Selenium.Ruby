module Applitools::Core
  class SessionStartInfo
    attr_accessor :app_id_or_name, :scenario_id_or_name

    def initialize(agent_id, app_id_or_name, scenario_id_or_name, batch_info, env_name, environment, match_level,
                   ver_id = nil, branch_name = nil, parent_branch_name = nil)
      @agent_id = agent_id
      @app_id_or_name = app_id_or_name
      @ver_id = ver_id
      @scenario_id_or_name = scenario_id_or_name
      @batch_info = batch_info
      @env_name = env_name
      @environment = environment
      @match_level = match_level
      @branch_name = branch_name
      @parent_branch_name = parent_branch_name
    end

    def to_hash
      {
          agent_id: @agent_id,
          app_id_or_name: @app_id_or_name,
          ver_id: @ver_id,
          scenario_id_or_name: @scenario_id_or_name,
          batch_info: @batch_info.to_hash,
          env_name: @env_name,
          environment: @environment.to_hash,
          match_level: @match_level,
          branch_name: @branch_name,
          parent_branch_name: @parent_branch_name
      }
    end
  end
end