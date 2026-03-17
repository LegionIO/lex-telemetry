# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Actor
        class Collector < Legion::Extensions::Actors::Every
          def runner_class
            'Legion::Extensions::Telemetry::Runners::Telemetry'
          end

          def runner_function
            'collect'
          end

          def time
            300
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
