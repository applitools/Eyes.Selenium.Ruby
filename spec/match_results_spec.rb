require 'spec_helper'

RSpec.describe Applitools::Core::MatchResults do
  it_should_behave_like "responds to method", [
      :as_expected, :as_expected=,
      :screenshot, :screenshot=,
      :window_id, :window_id=
  ]

end