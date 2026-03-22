# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Actor
        class RegionReporter < Legion::Extensions::Actors::Every
          def runner_class
            'Legion::Extensions::Telemetry::Runners::Telemetry'
          end

          def runner_function
            'region_metrics'
          end

          def time
            120
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
