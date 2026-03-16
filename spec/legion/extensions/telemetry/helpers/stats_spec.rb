# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/helpers/event_store'
require 'legion/extensions/telemetry/helpers/stats'

RSpec.describe Legion::Extensions::Telemetry::Helpers::Stats do
  let(:store) { Legion::Extensions::Telemetry::Helpers::EventStore.new }
  let(:now) { Time.now }

  before do
    store.store(event: Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :session_start, session_id: 'sess-1', source: :claude_code, timestamp: now
    ))
    store.store(event: Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :tool_call, session_id: 'sess-1', source: :claude_code, timestamp: now,
      tool_name: 'Read', tool_input: { file_path: '/a.rb' },
      tokens: { input: 100, output: 50, cache_read: 200, cache_write: 0 }, duration_ms: 500
    ))
    store.store(event: Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :tool_call, session_id: 'sess-1', source: :claude_code, timestamp: now,
      tool_name: 'Read', tool_input: { file_path: '/b.rb' },
      tokens: { input: 80, output: 30, cache_read: 150, cache_write: 10 }, duration_ms: 300
    ))
    store.store(event: Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :tool_call, session_id: 'sess-1', source: :claude_code, timestamp: now,
      tool_name: 'Bash', duration_ms: 1200
    ))
    store.store(event: Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :error, session_id: 'sess-1', source: :claude_code, timestamp: now,
      error: 'something failed'
    ))
  end

  describe '.session_summary' do
    it 'returns tool counts' do
      result = described_class.session_summary(store: store, session_id: 'sess-1')
      expect(result[:tool_counts]).to include('Read' => 2, 'Bash' => 1)
    end

    it 'returns total token usage' do
      result = described_class.session_summary(store: store, session_id: 'sess-1')
      expect(result[:tokens][:input]).to eq(180)
      expect(result[:tokens][:output]).to eq(80)
    end

    it 'returns error count' do
      result = described_class.session_summary(store: store, session_id: 'sess-1')
      expect(result[:error_count]).to eq(1)
    end

    it 'returns unique files accessed' do
      result = described_class.session_summary(store: store, session_id: 'sess-1')
      expect(result[:unique_files]).to contain_exactly('/a.rb', '/b.rb')
    end
  end

  describe '.aggregate_stats' do
    it 'returns cross-session totals' do
      result = described_class.aggregate_stats(store: store)
      expect(result[:session_count]).to eq(1)
      expect(result[:total_events]).to be >= 5
      expect(result[:tool_frequency]).to include('Read' => 2)
    end
  end
end
