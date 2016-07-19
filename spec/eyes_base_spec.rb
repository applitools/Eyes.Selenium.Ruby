require 'spec_helper'

describe Applitools::Core::EyesBase do
  it_should_behave_like "responds to method", [:agent_id, :agent_id=,
          :api_key, :api_key=,
          :server_url, :server_url=,
          :proxy, :proxy=,
          :disabled?, :disabled=,
          :app_name, :app_name=,
          :branch_name, :branch_name=,
          :parent_branch_name, :parent_branch_name=,
          :clear_user_inputs,
          :get_user_inputs,
          :match_timeout, :match_timeout=,
          :save_new_tests, :save_new_tests=,
          :save_failed_tests, :save_failed_tests=,
          :batch, :batch=,
          :failure_reports, :failure_reports=,
          :default_match_settings, :default_match_settings=,
          :open?,
          :log_handler, :log_handler=,
          :scale_ratio, :scale_ratio=,
          :scale_method, :scale_method=,
          :image_cut=,
          :close,
          :close_response_time,
          :abort_if_not_closed,
          :host_os, :host_os=,
          :host_app, :host_app=,
          :base_line_name, :base_line_name=,
          :position_provider, :position_provider=,
          :open_base
  ]
  it_should_behave_like "proxy method", Applitools::Connectivity::ServerConnector, [:api_key, :api_key=,
                                                                                     :server_url, :server_url=,
                                                                                     :proxy, :proxy=, :set_proxy
  ]

  it_should_behave_like "proxy method", Applitools::EyesLogger, [:log_handler, :log_handler=]
end