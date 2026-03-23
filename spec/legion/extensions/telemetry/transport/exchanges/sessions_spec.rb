# frozen_string_literal: true

require 'spec_helper'

require 'legion/extensions/telemetry/transport/exchanges/sessions'

RSpec.describe Legion::Extensions::Telemetry::Transport::Exchanges::Sessions do
  subject(:exchange) { described_class.allocate }

  it 'has exchange name telemetry.sessions' do
    expect(exchange.exchange_name).to eq('telemetry.sessions')
  end
end
