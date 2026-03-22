# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Runners
        module Telemetry
          module_function

          SCAN_DIRS = [
            File.expand_path('~/.claude/projects')
          ].freeze

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

          def publish_pending(**_opts)
            if privacy_mode?
              count = event_store.pending.length
              Legion::Logging.info "lex-telemetry: privacy mode active, suppressing #{count} pending events (local logging only)" if defined?(Legion::Logging)
              event_store.pending.clear
              return { success: true, published: 0, suppressed: true, reason: 'enterprise_data_privacy is enabled' }
            end

            events = event_store.flush_pending
            return { success: true, published: 0 } if events.empty?

            published = 0
            events.each do |event|
              if defined?(Legion::Extensions::Telemetry::Transport::Messages::TelemetryMessage)
                routing_key = "telemetry.#{event[:source]}.#{event[:event_type]}"
                Transport::Messages::TelemetryMessage.new.publish(event, routing_key: routing_key)
                published += 1
              end
            rescue StandardError
              event_store.pending.push(event)
            end

            { success: true, published: published, remaining: event_store.pending.length }
          rescue StandardError => e
            { success: false, error: e.message }
          end

          def high_water_mark
            @high_water_mark ||= Helpers::HighWaterMark.new
          end

          def collect(**_opts)
            files_processed = 0
            events_ingested = 0

            SCAN_DIRS.each do |dir|
              next unless Dir.exist?(dir)

              Dir.glob(File.join(dir, '**', '*.jsonl')).each do |path|
                next if high_water_mark.ingested?(path: path)

                current_size = File.size(path)
                last_offset = high_water_mark.get(path: path)
                next if current_size <= last_offset

                parser = parsers.find { |p| p.can_parse?(path) }
                next unless parser

                count = 0
                new_offset = parser.parse(path, offset: last_offset) do |event|
                  scrubbed = Helpers::Scrubber.scrub(event: event, level: :standard)
                  event_store.store(event: scrubbed)
                  count += 1
                end

                high_water_mark.set(path: path, offset: new_offset)
                files_processed += 1
                events_ingested += count
              rescue StandardError
                next
              end
            end

            { success: true, files_processed: files_processed, events_ingested: events_ingested }
          rescue StandardError => e
            { success: false, error: e.message }
          end

          def region_metrics(**_opts)
            region_info = if defined?(Legion::Region)
                            {
                              current:  Legion::Region.current,
                              primary:  Legion::Region.primary,
                              failover: Legion::Region.failover,
                              peers:    Legion::Region.peers
                            }
                          else
                            { current: nil, primary: nil, failover: nil, peers: [] }
                          end

            affinity = if defined?(Legion::Settings)
                         begin
                           Legion::Settings.dig(:region, :default_affinity)
                         rescue StandardError
                           'prefer_local'
                         end
                       else
                         'prefer_local'
                       end

            is_primary = region_info[:current] && region_info[:current] == region_info[:primary]

            {
              success:          true,
              region:           region_info,
              default_affinity: affinity,
              is_primary:       is_primary,
              timestamp:        Time.now.to_i
            }
          rescue StandardError => e
            { success: false, error: e.message }
          end

          def privacy_mode?
            if defined?(Legion::Settings) && Legion::Settings.respond_to?(:enterprise_privacy?)
              Legion::Settings.enterprise_privacy?
            else
              ENV['LEGION_ENTERPRISE_PRIVACY'] == 'true'
            end
          end

          def reset!
            @event_store = nil
            @parsers = nil
            @high_water_mark = nil
          end
        end
      end
    end
  end
end
