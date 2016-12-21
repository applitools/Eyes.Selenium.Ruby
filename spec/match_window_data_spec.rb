require 'spec_helper'

RSpec.describe Applitools::Core::MatchWindowData do
  let(:app_output) do
    Object.new.tap do |o|
      o.instance_eval do
        define_singleton_method :to_hash do
          :app_output
        end
      end
    end
  end
  subject { Applitools::Core::MatchWindowData.new(:user_inputs, app_output, :tag, :ignore_mismatch) }
  it_should_behave_like 'responds to method', [
    :app_output,
    :app_output=,
    :user_inputs,
    :user_inputs=,
    :tag,
    :tag=,
    :options,
    :options=,
    :ignore_mismatch,
    :ignore_mismatch=,
    :appOutput,
    :userInputs,
    :ignoreMismatch,
    :to_s,
    :to_hash
  ]

  it 'tries convert using to_hash' do
    expect(app_output).to receive(:to_hash)
    subject.to_hash
  end

  it 'returns data as hash' do
    result = subject.to_hash
    expect(result.keys).to include(:userInputs, :appOutput, :tag, :ignoreMismatch)
    expect(result).to a_hash_including(
      :userInputs => :user_inputs,
      :appOutput => :app_output,
      :tag => :tag,
      :ignoreMismatch => :ignore_mismatch
    )
  end
end
