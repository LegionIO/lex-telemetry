# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Transport
        module Queues
          class SessionsProcess < Legion::Transport::Queue
            def queue_name = 'telemetry.sessions.process'
            def queue_options = { auto_delete: false }
          end
        end
      end
    end
  end
end
