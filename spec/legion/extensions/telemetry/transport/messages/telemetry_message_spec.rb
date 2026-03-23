# frozen_string_literal: true

require 'spec_helper'

require 'legion/extensions/telemetry/transport/exchanges/sessions'
require 'legion/extensions/telemetry/transport/messages/telemetry_message'

RSpec.describe Legion::Extensions::Telemetry::Transport::Messages::TelemetryMessage do
  subject(:message) { described_class.allocate }

  it 'routes to telemetry.sessions.process' do
    expect(message.routing_key).to eq('telemetry.sessions.process')
  end

  it 'uses the Sessions exchange' do
    expect(message.exchange).to eq(Legion::Extensions::Telemetry::Transport::Exchanges::Sessions)
  end
end
