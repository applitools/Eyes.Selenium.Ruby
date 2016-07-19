module Applitools::Core
  class EyesBase
    extend Forwardable

    def_delegators 'Applitools::EyesLogger', :log_handler, :log_handler=
    def_delegators 'Applitools::Connectivity::ServerConnector', :api_key, :api_key=, :server_url, :server_url=, :set_proxy,
                   :proxy, :proxy=


  end
end

