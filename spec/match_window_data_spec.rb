require 'spec_helper'

RSpec.describe Applitools::Core::MatchWindowData do
  it_should_behave_like 'responds to method', [
    :app_output,
    :app_output=,
    :user_inputs,
    :user_inputs=,
    :tag,
    :tag=,
    :options,
    :options=,
    :ignore_mistmatch,
    :ignore_mistmatch=
  ]
end
