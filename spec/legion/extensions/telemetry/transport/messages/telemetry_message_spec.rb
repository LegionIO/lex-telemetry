# frozen_string_literal: true

require 'spec_helper'

unless defined?(Legion::Transport::Message)
  module Legion
    module Transport
      class Message
        def routing_key = nil
      end

      class Exchange
        def exchange_name = nil
      end
    end
  end
end

require 'legion/extensions/telemetry/transport/exchanges/sessions'
require 'legion/extensions/telemetry/transport/messages/telemetry_message'

RSpec.describe Legion::Extensions::Telemetry::Transport::Messages::TelemetryMessage do
  subject(:message) { described_class.new }

  it 'routes to telemetry.sessions.process' do
    expect(message.routing_key).to eq('telemetry.sessions.process')
  end

  it 'uses the Sessions exchange' do
    expect(message.exchange).to eq(Legion::Extensions::Telemetry::Transport::Exchanges::Sessions)
  end
end
