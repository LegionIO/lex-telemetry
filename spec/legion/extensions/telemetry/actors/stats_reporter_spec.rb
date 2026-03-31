# frozen_string_literal: true

require 'spec_helper'

require 'legion/extensions/telemetry/actors/stats_reporter'

RSpec.describe Legion::Extensions::Telemetry::Actor::StatsReporter do
  subject(:actor) { described_class.new }

  it 'runs every 60 seconds' do
    expect(actor.time).to eq(60)
  end

  it 'targets the telemetry runner' do
    expect(actor.runner_class).to eq('Legion::Extensions::Telemetry::Runners::Telemetry')
  end

  it 'calls system_stats' do
    expect(actor.runner_function).to eq('system_stats')
  end

  it 'does not run immediately' do
    expect(actor.run_now?).to be false
  end

  it 'does not use runner' do
    expect(actor.use_runner?).to be false
  end

  it 'does not check subtask' do
    expect(actor.check_subtask?).to be false
  end

  it 'does not generate a task' do
    expect(actor.generate_task?).to be false
  end
end
