# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Helpers
        module Stats
          module_function

          def session_summary(store:, session_id:)
            events = store.events_for(session_id: session_id)
            tool_events = events.select { |e| e[:event_type] == :tool_call }
            error_events = events.select { |e| e[:event_type] == :error }

            tool_counts = tool_events.each_with_object(Hash.new(0)) do |e, h|
              h[e[:tool_name]] += 1 if e[:tool_name]
            end

            tokens = sum_tokens(events)
            files = extract_files(tool_events)
            durations = tool_events.filter_map { |e| e[:duration_ms] }

            {
              session_id:        session_id,
              event_count:       events.length,
              tool_counts:       tool_counts,
              tokens:            tokens,
              error_count:       error_events.length,
              unique_files:      files,
              avg_duration_ms:   durations.empty? ? 0 : (durations.sum.to_f / durations.length).round,
              total_duration_ms: durations.sum
            }
          end

          def aggregate_stats(store:)
            tool_frequency = Hash.new(0)
            file_frequency = Hash.new(0)
            total_tokens = { input: 0, output: 0, cache_read: 0, cache_write: 0 }

            store.events.each do |e|
              tool_frequency[e[:tool_name]] += 1 if e[:event_type] == :tool_call && e[:tool_name]

              total_tokens.each_key { |k| total_tokens[k] += e[:tokens][k] || 0 } if e[:tokens].is_a?(Hash)

              file_frequency[e[:tool_input][:file_path]] += 1 if e[:tool_input].is_a?(Hash) && e[:tool_input][:file_path]
            end

            error_count = store.events.count { |e| e[:event_type] == :error }

            {
              session_count:   store.sessions.length,
              total_events:    store.events.length,
              tool_frequency:  tool_frequency,
              tokens:          total_tokens,
              error_count:     error_count,
              error_rate:      store.events.empty? ? 0.0 : (error_count.to_f / store.events.length).round(4),
              most_read_files: file_frequency.sort_by { |_, v| -v }.first(10).to_h
            }
          end

          def sum_tokens(events)
            totals = { input: 0, output: 0, cache_read: 0, cache_write: 0 }
            events.each do |e|
              next unless e[:tokens].is_a?(Hash)

              totals.each_key { |k| totals[k] += e[:tokens][k] || 0 }
            end
            totals
          end

          def extract_files(tool_events)
            tool_events.filter_map { |e| e[:tool_input]&.dig(:file_path) }.uniq
          end
        end
      end
    end
  end
end
