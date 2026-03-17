# frozen_string_literal: true

require 'spec_helper'

unless defined?(Legion::Extensions::Actors::Every)
  module Legion
    module Extensions
      module Actors
        class Every; end
      end
    end
  end
end

require 'legion/extensions/telemetry/actors/collector'

RSpec.describe Legion::Extensions::Telemetry::Actor::Collector do
  subject(:actor) { described_class.new }

  it 'runs every 300 seconds' do
    expect(actor.time).to eq(300)
  end

  it 'targets the telemetry runner' do
    expect(actor.runner_class).to eq('Legion::Extensions::Telemetry::Runners::Telemetry')
  end

  it 'calls collect' do
    expect(actor.runner_function).to eq('collect')
  end
end
