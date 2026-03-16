# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Helpers
        module TelemetryEvent
          VALID_EVENT_TYPES = %i[tool_call llm_request error session_start session_end].freeze

          module_function

          def build(event_type:, session_id:, source:, timestamp:, tool_name: nil,
                    tool_input: nil, duration_ms: nil, tokens: nil, error: nil, metadata: nil)
            raise ArgumentError, "invalid event_type: #{event_type}" unless VALID_EVENT_TYPES.include?(event_type)

            {
              event_type:  event_type,
              session_id:  session_id,
              source:      source,
              timestamp:   timestamp,
              tool_name:   tool_name,
              tool_input:  tool_input,
              duration_ms: duration_ms,
              tokens:      tokens,
              error:       error,
              metadata:    metadata
            }
          end
        end
      end
    end
  end
end
