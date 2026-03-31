# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/helpers/scrubber'
require 'legion/extensions/telemetry/helpers/event_store'
require 'legion/extensions/telemetry/helpers/stats'
require 'legion/extensions/telemetry/helpers/subsystem_stats'
require 'legion/extensions/telemetry/parsers/base'
require 'legion/extensions/telemetry/parsers/claude_code'
require 'legion/extensions/telemetry/runners/telemetry'
require 'json'
require 'tempfile'

RSpec.describe Legion::Extensions::Telemetry::Runners::Telemetry do
  let(:runner) { described_class }

  before { runner.reset! }

  let(:session_start_line) do
    { 'parentUuid' => '', 'type' => 'summary', 'sessionId' => 'sess-abc',
      'version' => '1.0', 'timestamp' => '2026-03-15T10:00:00Z' }.to_json
  end

  let(:tool_use_line) do
    { 'parentUuid' => 'msg-1', 'type' => 'assistant', 'uuid' => 'msg-2',
      'message' => {
        'role'    => 'assistant',
        'content' => [{ 'type' => 'tool_use', 'id' => 'tool-1', 'name' => 'Read',
                        'input' => { 'file_path' => '/path/file.rb' } }],
        'usage'   => { 'input_tokens' => 100, 'output_tokens' => 50,
                       'cache_read_input_tokens' => 200, 'cache_creation_input_tokens' => 0 }
      },
      'timestamp' => '2026-03-15T10:00:05Z' }.to_json
  end

  let(:tool_result_line) do
    { 'parentUuid' => 'msg-2', 'type' => 'user', 'uuid' => 'msg-3',
      'message' => {
        'role'    => 'user',
        'content' => [{ 'type' => 'tool_result', 'tool_use_id' => 'tool-1', 'content' => 'data' }]
      },
      'timestamp' => '2026-03-15T10:00:06Z' }.to_json
  end

  def write_fixture(*lines)
    file = Tempfile.new(['session', '.jsonl'])
    lines.each { |l| file.puts(l) }
    file.close
    file
  end

  describe '.ingest_session' do
    it 'parses, scrubs, and stores events; returns summary' do
      file = write_fixture(session_start_line, tool_use_line, tool_result_line)
      result = runner.ingest_session(file_path: file.path)
      expect(result[:success]).to be true
      expect(result[:event_count]).to be >= 2
      expect(result[:session_id]).to eq('sess-abc')
      file.unlink
    end
  end

  describe '.session_stats' do
    it 'returns per-session breakdown' do
      file = write_fixture(session_start_line, tool_use_line, tool_result_line)
      runner.ingest_session(file_path: file.path)
      result = runner.session_stats(session_id: 'sess-abc')
      expect(result[:success]).to be true
      expect(result[:stats][:tool_counts]).to include('Read' => 1)
      file.unlink
    end

    it 'returns failure for unknown session' do
      result = runner.session_stats(session_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '.aggregate_stats' do
    it 'returns cross-session totals' do
      file = write_fixture(session_start_line, tool_use_line, tool_result_line)
      runner.ingest_session(file_path: file.path)
      result = runner.aggregate_stats
      expect(result[:success]).to be true
      expect(result[:stats][:session_count]).to be >= 1
      file.unlink
    end
  end

  describe '.telemetry_status' do
    it 'returns buffer and publisher state' do
      result = runner.telemetry_status
      expect(result[:success]).to be true
      expect(result).to have_key(:buffer_size)
      expect(result).to have_key(:pending_count)
    end
  end

  describe '.collect' do
    it 'returns success with counts' do
      result = runner.collect
      expect(result[:success]).to be true
      expect(result).to have_key(:files_processed)
      expect(result).to have_key(:events_ingested)
    end
  end

  describe '.publish_pending' do
    it 'returns published count when empty' do
      result = runner.publish_pending
      expect(result[:success]).to be true
      expect(result[:published]).to eq(0)
    end
  end

  describe '.system_stats' do
    it 'returns success with a stats hash' do
      result = runner.system_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to be_a(Hash)
    end

    it 'includes a timestamp in stats' do
      result = runner.system_stats
      expect(result[:stats][:timestamp]).to be_a(Integer)
    end

    it 'omits nil subsystem entries' do
      result = runner.system_stats
      result[:stats].each_value do |v|
        expect(v).not_to be_nil
      end
    end
  end
end
