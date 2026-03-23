# frozen_string_literal: true

require 'spec_helper'

require 'legion/extensions/telemetry/transport/queues/sessions_process'

RSpec.describe Legion::Extensions::Telemetry::Transport::Queues::SessionsProcess do
  subject(:queue) { described_class.allocate }

  it 'has queue name telemetry.sessions.process' do
    expect(queue.queue_name).to eq('telemetry.sessions.process')
  end

  it 'is not auto-delete' do
    expect(queue.queue_options).to include(auto_delete: false)
  end
end
