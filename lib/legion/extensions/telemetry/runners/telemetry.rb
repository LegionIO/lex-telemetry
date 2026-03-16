# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Runners
        module Telemetry
          module_function

          def event_store
            @event_store ||= Helpers::EventStore.new
          end

          def parsers
            @parsers ||= [Parsers::ClaudeCode.new]
          end

          def ingest_session(file_path:, scrub_level: :standard, **_opts)
            parser = parsers.find { |p| p.can_parse?(file_path) }
            return { success: false, error: 'no parser found' } unless parser

            session_id = nil
            count = 0

            parser.parse(file_path) do |event|
              scrubbed = Helpers::Scrubber.scrub(event: event, level: scrub_level)
              event_store.store(event: scrubbed)
              session_id ||= scrubbed[:session_id]
              count += 1
            end

            { success: true, session_id: session_id, event_count: count, file_path: file_path }
          rescue StandardError => e
            { success: false, error: e.message }
          end

          def session_stats(session_id:, **_opts)
            events = event_store.events_for(session_id: session_id)
            return { success: false, error: 'session not found' } if events.empty?

            stats = Helpers::Stats.session_summary(store: event_store, session_id: session_id)
            { success: true, stats: stats }
          end

          def aggregate_stats(**_opts)
            stats = Helpers::Stats.aggregate_stats(store: event_store)
            { success: true, stats: stats }
          end

          def telemetry_status(**_opts)
            {
              success:       true,
              buffer_size:   event_store.events.length,
              pending_count: event_store.pending.length,
              session_count: event_store.sessions.length,
              parsers:       parsers.map(&:source_name)
            }
          end

          def reset!
            @event_store = nil
            @parsers = nil
          end
        end
      end
    end
  end
end
