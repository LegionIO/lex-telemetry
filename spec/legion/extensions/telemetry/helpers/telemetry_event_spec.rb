# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/telemetry_event'

RSpec.describe Legion::Extensions::Telemetry::Helpers::TelemetryEvent do
  describe '.build' do
    it 'creates an event with all required fields' do
      event = described_class.build(
        event_type: :tool_call,
        session_id: 'abc-123',
        source:     :claude_code,
        timestamp:  Time.now,
        tool_name:  'Read'
      )
      expect(event[:event_type]).to eq(:tool_call)
      expect(event[:session_id]).to eq('abc-123')
      expect(event[:source]).to eq(:claude_code)
      expect(event[:tool_name]).to eq('Read')
    end

    it 'defaults optional fields to nil' do
      event = described_class.build(
        event_type: :session_start,
        session_id: 'abc-123',
        source:     :claude_code,
        timestamp:  Time.now
      )
      expect(event[:tool_name]).to be_nil
      expect(event[:tool_input]).to be_nil
      expect(event[:duration_ms]).to be_nil
      expect(event[:error]).to be_nil
    end

    it 'includes token counts when provided' do
      event = described_class.build(
        event_type: :llm_request,
        session_id: 'abc-123',
        source:     :claude_code,
        timestamp:  Time.now,
        tokens:     { input: 100, output: 50, cache_read: 200, cache_write: 0 }
      )
      expect(event[:tokens][:input]).to eq(100)
      expect(event[:tokens][:output]).to eq(50)
    end

    it 'validates event_type' do
      expect do
        described_class.build(
          event_type: :invalid,
          session_id: 'abc-123',
          source:     :claude_code,
          timestamp:  Time.now
        )
      end.to raise_error(ArgumentError, /event_type/)
    end
  end

  describe 'VALID_EVENT_TYPES' do
    it 'includes all five event types' do
      expect(described_class::VALID_EVENT_TYPES).to contain_exactly(
        :tool_call, :llm_request, :error, :session_start, :session_end
      )
    end
  end
end
