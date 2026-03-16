# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Helpers
        class EventStore
          MAX_BUFFER = 10_000

          attr_reader :events, :pending, :sessions

          def initialize
            @events   = []
            @pending  = []
            @sessions = {}
          end

          def store(event:)
            @events.shift if @events.length >= MAX_BUFFER
            @events << event
            @pending << event

            sid = event[:session_id]
            @sessions[sid] ||= { first_seen: event[:timestamp], event_count: 0 }
            @sessions[sid][:event_count] += 1
            @sessions[sid][:last_seen] = event[:timestamp]
          end

          def flush_pending
            flushed = @pending.dup
            @pending.clear
            flushed
          end

          def events_for(session_id:)
            @events.select { |e| e[:session_id] == session_id }
          end
        end
      end
    end
  end
end
