# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/helpers/event_store'

RSpec.describe Legion::Extensions::Telemetry::Helpers::EventStore do
  subject(:store) { described_class.new }

  let(:event) do
    Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :tool_call, session_id: 'sess-1', source: :claude_code,
      timestamp: Time.now, tool_name: 'Read', tool_input: { file_path: '/a.rb' }
    )
  end

  describe '#store' do
    it 'adds event to events and pending' do
      store.store(event: event)
      expect(store.events.length).to eq(1)
      expect(store.pending.length).to eq(1)
    end

    it 'tracks session metadata' do
      store.store(event: event)
      expect(store.sessions).to have_key('sess-1')
    end
  end

  describe '#flush_pending' do
    it 'returns and clears pending events' do
      store.store(event: event)
      flushed = store.flush_pending
      expect(flushed.length).to eq(1)
      expect(store.pending).to be_empty
    end

    it 'does not clear events buffer' do
      store.store(event: event)
      store.flush_pending
      expect(store.events.length).to eq(1)
    end
  end

  describe '#events_for' do
    it 'filters by session_id' do
      store.store(event: event)
      other = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
        event_type: :tool_call, session_id: 'sess-2', source: :claude_code,
        timestamp: Time.now, tool_name: 'Glob'
      )
      store.store(event: other)
      expect(store.events_for(session_id: 'sess-1').length).to eq(1)
    end
  end

  describe 'MAX_BUFFER cap' do
    it 'drops oldest events when buffer exceeds cap' do
      (described_class::MAX_BUFFER + 5).times do |i|
        e = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
          event_type: :tool_call, session_id: "sess-#{i}", source: :claude_code,
          timestamp: Time.now, tool_name: 'Read'
        )
        store.store(event: e)
      end
      expect(store.events.length).to eq(described_class::MAX_BUFFER)
    end
  end
end
