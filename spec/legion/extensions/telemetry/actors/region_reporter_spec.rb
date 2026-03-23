# frozen_string_literal: true

require 'spec_helper'

require 'legion/extensions/telemetry/actors/region_reporter'

RSpec.describe Legion::Extensions::Telemetry::Actor::RegionReporter do
  subject(:actor) { described_class.new }

  it 'runs every 60 seconds' do
    expect(actor.time).to eq(60)
  end

  it 'targets the telemetry runner' do
    expect(actor.runner_class).to eq('Legion::Extensions::Telemetry::Runners::Telemetry')
  end

  it 'calls region_stats' do
    expect(actor.runner_function).to eq('region_stats')
  end

  it 'does not run immediately' do
    expect(actor.run_now?).to be false
  end
end
