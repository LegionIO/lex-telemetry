# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Transport
        module Exchanges
          class Sessions < Legion::Transport::Exchange
            def exchange_name = 'telemetry.sessions'
          end
        end
      end
    end
  end
end
