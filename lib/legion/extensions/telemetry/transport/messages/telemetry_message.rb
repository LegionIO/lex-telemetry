# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Transport
        module Messages
          class TelemetryMessage < Legion::Transport::Message
            def routing_key = 'telemetry.sessions.process'
            def exchange    = Legion::Extensions::Telemetry::Transport::Exchanges::Sessions
          end
        end
      end
    end
  end
end
