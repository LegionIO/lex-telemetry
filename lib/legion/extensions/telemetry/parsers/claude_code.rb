# frozen_string_literal: true

require 'json'
require 'time'

module Legion
  module Extensions
    module Telemetry
      module Parsers
        class ClaudeCode
          include Base

          def source_name
            :claude_code
          end

          def can_parse?(path)
            first_line = File.open(path, &:readline)
            data = ::JSON.parse(first_line)
            data.is_a?(Hash) && (data.key?('sessionId') || data.key?('parentUuid'))
          rescue StandardError => _e
            false
          end

          def parse(path, offset: 0, &)
            pending_tools = {}
            session_id = nil

            File.open(path) do |f|
              f.seek(offset) if offset.positive?
              first_line = offset.zero?

              f.each_line do |line|
                data = ::JSON.parse(line.strip)
                timestamp = parse_timestamp(data['timestamp'])

                if first_line && offset.zero?
                  session_id = data['sessionId'] || data['uuid'] || SecureRandom.uuid
                  yield(Helpers::TelemetryEvent.build(
                    event_type: :session_start,
                    session_id: session_id,
                    source:     source_name,
                    timestamp:  timestamp,
                    metadata:   { version: data['version'] }
                  ))
                  first_line = false
                  next
                end

                session_id ||= data['sessionId'] || 'unknown'
                msg = data['message']
                next unless msg.is_a?(Hash)

                process_assistant(msg, session_id, timestamp, pending_tools, &) if msg['role'] == 'assistant'
                process_tool_result(msg, session_id, timestamp, pending_tools, &) if msg['role'] == 'user'
              rescue ::JSON::ParserError => _e
                next
              end

              return f.pos
            end
          end

          private

          def process_assistant(msg, session_id, timestamp, pending_tools)
            content = msg['content']
            usage = msg['usage']

            if content.is_a?(Array)
              content.each do |item|
                next unless item['type'] == 'tool_use'

                pending_tools[item['id']] = {
                  tool_name:  item['name'],
                  tool_input: symbolize_keys(item['input']),
                  timestamp:  timestamp,
                  tokens:     extract_tokens(usage)
                }
              end
            end

            return unless usage

            has_tool_use = content.is_a?(Array) && content.any? { |b| b['type'] == 'tool_use' }
            return if has_tool_use

            yield(Helpers::TelemetryEvent.build(
              event_type: :llm_request,
              session_id: session_id,
              source:     source_name,
              timestamp:  timestamp,
              tokens:     extract_tokens(usage)
            ))
          end

          def process_tool_result(msg, session_id, timestamp, pending_tools)
            content = msg['content']
            return unless content.is_a?(Array)

            content.each do |item|
              next unless item['type'] == 'tool_result'

              pending = pending_tools.delete(item['tool_use_id'])
              next unless pending

              duration_ms = ((timestamp - pending[:timestamp]) * 1000).to_i if timestamp && pending[:timestamp]

              yield(Helpers::TelemetryEvent.build(
                event_type:  :tool_call,
                session_id:  session_id,
                source:      source_name,
                timestamp:   pending[:timestamp],
                tool_name:   pending[:tool_name],
                tool_input:  pending[:tool_input],
                duration_ms: duration_ms,
                tokens:      pending[:tokens]
              ))
            end
          end

          def extract_tokens(usage)
            return nil unless usage.is_a?(Hash)

            {
              input:       usage['input_tokens'] || 0,
              output:      usage['output_tokens'] || 0,
              cache_read:  usage['cache_read_input_tokens'] || 0,
              cache_write: usage['cache_creation_input_tokens'] || 0
            }
          end

          def parse_timestamp(str)
            return nil unless str

            Time.parse(str)
          rescue ArgumentError => _e
            nil
          end

          def symbolize_keys(hash)
            return nil unless hash.is_a?(Hash)

            hash.transform_keys(&:to_sym)
          end
        end
      end
    end
  end
end
