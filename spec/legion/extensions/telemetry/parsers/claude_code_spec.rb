# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/parsers/base'
require 'legion/extensions/telemetry/parsers/claude_code'
require 'json'
require 'tempfile'

RSpec.describe Legion::Extensions::Telemetry::Parsers::ClaudeCode do
  let(:session_id) { 'test-session-uuid' }

  let(:session_start_line) do
    { 'parentUuid' => '', 'type' => 'summary', 'sessionId' => session_id,
      'version' => '1.0', 'timestamp' => '2026-03-15T10:00:00Z' }.to_json
  end

  let(:tool_use_line) do
    { 'parentUuid' => 'msg-1', 'type' => 'assistant', 'uuid' => 'msg-2',
      'message' => {
        'role'    => 'assistant',
        'content' => [
          { 'type' => 'tool_use', 'id' => 'tool-1', 'name' => 'Read',
            'input' => { 'file_path' => '/path/to/file.rb' } }
        ],
        'usage'   => { 'input_tokens' => 100, 'output_tokens' => 50,
                       'cache_read_input_tokens'    => 200, 'cache_creation_input_tokens' => 0 }
      },
      'timestamp' => '2026-03-15T10:00:05Z' }.to_json
  end

  let(:tool_result_line) do
    { 'parentUuid' => 'msg-2', 'type' => 'user', 'uuid' => 'msg-3',
      'message'    => {
        'role'    => 'user',
        'content' => [
          { 'type' => 'tool_result', 'tool_use_id' => 'tool-1', 'content' => 'file contents...' }
        ]
      },
      'timestamp'  => '2026-03-15T10:00:06Z' }.to_json
  end

  let(:llm_only_line) do
    { 'parentUuid' => 'msg-3', 'type' => 'assistant', 'uuid' => 'msg-4',
      'message'    => {
        'role'    => 'assistant',
        'content' => [{ 'type' => 'text', 'text' => 'Here is the answer.' }],
        'usage'   => { 'input_tokens' => 300, 'output_tokens' => 150,
                       'cache_read_input_tokens'    => 500, 'cache_creation_input_tokens' => 100 }
      },
      'timestamp' => '2026-03-15T10:00:10Z' }.to_json
  end

  def write_fixture(*lines)
    file = Tempfile.new(['session', '.jsonl'])
    lines.each { |l| file.puts(l) }
    file.close
    file
  end

  describe '#source_name' do
    it 'returns :claude_code' do
      expect(described_class.new.source_name).to eq(:claude_code)
    end
  end

  describe '#can_parse?' do
    it 'returns true for Claude Code JSONL' do
      file = write_fixture(session_start_line)
      expect(described_class.new.can_parse?(file.path)).to be true
      file.unlink
    end

    it 'returns false for non-JSONL' do
      file = Tempfile.new(['other', '.txt'])
      file.write('not json')
      file.close
      expect(described_class.new.can_parse?(file.path)).to be false
      file.unlink
    end
  end

  describe '#parse' do
    it 'yields tool_call events for tool_use blocks' do
      file = write_fixture(session_start_line, tool_use_line, tool_result_line)
      events = []
      described_class.new.parse(file.path) { |e| events << e }
      tool_events = events.select { |e| e[:event_type] == :tool_call }
      expect(tool_events.length).to eq(1)
      expect(tool_events.first[:tool_name]).to eq('Read')
      expect(tool_events.first[:tool_input]).to include(file_path: '/path/to/file.rb')
      file.unlink
    end

    it 'computes duration_ms from tool_use to tool_result timestamps' do
      file = write_fixture(session_start_line, tool_use_line, tool_result_line)
      events = []
      described_class.new.parse(file.path) { |e| events << e }
      tool_event = events.find { |e| e[:event_type] == :tool_call }
      expect(tool_event[:duration_ms]).to eq(1000)
      file.unlink
    end

    it 'yields llm_request events for assistant messages with usage' do
      file = write_fixture(session_start_line, llm_only_line)
      events = []
      described_class.new.parse(file.path) { |e| events << e }
      llm_events = events.select { |e| e[:event_type] == :llm_request }
      expect(llm_events.length).to eq(1)
      expect(llm_events.first[:tokens][:input]).to eq(300)
      expect(llm_events.first[:tokens][:output]).to eq(150)
      file.unlink
    end

    it 'yields session_start for the first line' do
      file = write_fixture(session_start_line, llm_only_line)
      events = []
      described_class.new.parse(file.path) { |e| events << e }
      start_events = events.select { |e| e[:event_type] == :session_start }
      expect(start_events.length).to eq(1)
      expect(start_events.first[:session_id]).to eq(session_id)
      file.unlink
    end

    it 'supports byte offset for incremental reads' do
      file = write_fixture(session_start_line, tool_use_line, tool_result_line, llm_only_line)
      first_events = []
      offset = described_class.new.parse(file.path) { |e| first_events << e }
      expect(first_events.length).to be >= 3

      second_events = []
      described_class.new.parse(file.path, offset: offset) { |e| second_events << e }
      expect(second_events).to be_empty
      file.unlink
    end
  end
end
