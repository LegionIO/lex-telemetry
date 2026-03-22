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

require 'legion/extensions/telemetry/actors/region_reporter'

RSpec.describe Legion::Extensions::Telemetry::Actor::RegionReporter do
  subject(:actor) { described_class.new }

  it 'runs every 120 seconds' do
    expect(actor.time).to eq(120)
  end

  it 'targets the telemetry runner' do
    expect(actor.runner_class).to eq('Legion::Extensions::Telemetry::Runners::Telemetry')
  end

  it 'calls region_metrics' do
    expect(actor.runner_function).to eq('region_metrics')
  end

  it 'does not run immediately' do
    expect(actor.run_now?).to be false
  end
end
