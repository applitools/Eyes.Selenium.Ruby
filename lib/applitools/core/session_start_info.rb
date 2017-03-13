module Applitools::Core
  class SessionStartInfo
    attr_accessor :app_id_or_name, :scenario_id_or_name

    def initialize(options = {})
      @agent_id = options[:agent_id]
      @app_id_or_name = options[:app_id_or_name]
      @ver_id = options[:ver_id]
      @scenario_id_or_name = options[:scenario_id_or_name]
      @batch_info = options[:batch_info]
      @env_name = options[:env_name]
      @environment = options[:environment]
      @match_level = options[:match_level]
      @branch_name = options[:branch_name]
      @parent_branch_name = options[:parent_branch_name]
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
