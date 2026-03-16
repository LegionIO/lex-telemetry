# frozen_string_literal: true

require 'spec_helper'

unless defined?(Legion::Transport::Exchange)
  module Legion
    module Transport
      class Exchange
        def exchange_name = nil
      end
    end
  end
end

require 'legion/extensions/telemetry/transport/exchanges/sessions'

RSpec.describe Legion::Extensions::Telemetry::Transport::Exchanges::Sessions do
  subject(:exchange) { described_class.new }

  it 'has exchange name telemetry.sessions' do
    expect(exchange.exchange_name).to eq('telemetry.sessions')
  end
end
