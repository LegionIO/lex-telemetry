# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/helpers/scrubber'

RSpec.describe Legion::Extensions::Telemetry::Helpers::Scrubber do
  let(:base_event) do
    Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
      event_type: :tool_call,
      session_id: 'abc-123',
      source:     :claude_code,
      timestamp:  Time.now,
      tool_name:  'Read',
      tool_input: { file_path: '/path/to/file.rb', offset: 10, limit: 50, secret: 'should_be_stripped' }
    )
  end

  describe '.scrub' do
    context 'with :standard level (default)' do
      it 'keeps whitelisted tool input keys' do
        result = described_class.scrub(event: base_event)
        expect(result[:tool_input]).to include(:file_path, :offset, :limit)
      end

      it 'strips non-whitelisted tool input keys' do
        result = described_class.scrub(event: base_event)
        expect(result[:tool_input]).not_to have_key(:secret)
      end

      it 'strips Bash command but keeps description' do
        event = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
          event_type: :tool_call,
          session_id: 'abc-123',
          source:     :claude_code,
          timestamp:  Time.now,
          tool_name:  'Bash',
          tool_input: { command: 'rm -rf /', description: 'delete files', timeout: 30 }
        )
        result = described_class.scrub(event: event)
        expect(result[:tool_input]).not_to have_key(:command)
        expect(result[:tool_input][:description]).to eq('delete files')
        expect(result[:tool_input][:timeout]).to eq(30)
      end

      it 'strips Write content but keeps file_path' do
        event = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
          event_type: :tool_call,
          session_id: 'abc-123',
          source:     :claude_code,
          timestamp:  Time.now,
          tool_name:  'Write',
          tool_input: { file_path: '/path/file.rb', content: 'secret code here' }
        )
        result = described_class.scrub(event: event)
        expect(result[:tool_input][:file_path]).to eq('/path/file.rb')
        expect(result[:tool_input]).not_to have_key(:content)
      end
    end

    context 'with :minimal level' do
      it 'keeps all tool input keys' do
        result = described_class.scrub(event: base_event, level: :minimal)
        expect(result[:tool_input]).to include(:file_path, :secret)
      end
    end

    context 'with :paranoid level' do
      it 'strips all tool input' do
        result = described_class.scrub(event: base_event, level: :paranoid)
        expect(result[:tool_input]).to be_nil
      end

      it 'keeps event_type, tool_name, timestamp, tokens' do
        result = described_class.scrub(event: base_event, level: :paranoid)
        expect(result[:event_type]).to eq(:tool_call)
        expect(result[:tool_name]).to eq('Read')
        expect(result[:timestamp]).not_to be_nil
      end
    end

    context 'with PII scrubbing' do
      it 'redacts email addresses in string values' do
        event = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
          event_type: :tool_call,
          session_id: 'abc-123',
          source:     :claude_code,
          timestamp:  Time.now,
          tool_name:  'Grep',
          tool_input: { pattern: 'user@example.com', path: '/src' }
        )
        result = described_class.scrub(event: event)
        expect(result[:tool_input][:pattern]).to eq('[EMAIL]')
      end

      it 'redacts SSN patterns' do
        event = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
          event_type: :tool_call,
          session_id: 'abc-123',
          source:     :claude_code,
          timestamp:  Time.now,
          tool_name:  'Grep',
          tool_input: { pattern: '123-45-6789', path: '/src' }
        )
        result = described_class.scrub(event: event)
        expect(result[:tool_input][:pattern]).to eq('[SSN]')
      end
    end

    context 'with unknown tool' do
      it 'strips all tool input at standard level' do
        event = Legion::Extensions::Telemetry::Helpers::TelemetryEvent.build(
          event_type: :tool_call,
          session_id: 'abc-123',
          source:     :claude_code,
          timestamp:  Time.now,
          tool_name:  'UnknownTool',
          tool_input: { data: 'anything' }
        )
        result = described_class.scrub(event: event)
        expect(result[:tool_input]).to be_nil
      end
    end
  end

  describe 'TOOL_WHITELIST' do
    it 'defines whitelists for known tools' do
      expect(described_class::TOOL_WHITELIST).to include('Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'Agent')
    end
  end
end
