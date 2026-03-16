# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Helpers
        class HighWaterMark
          def initialize
            @marks = {}
            @completed = Set.new
          end

          def get(path:)
            @marks.fetch(path, 0)
          end

          def set(path:, offset:)
            @marks[path] = offset
          end

          def ingested?(path:)
            @completed.include?(path)
          end

          def mark_complete(path:)
            @completed.add(path)
          end
        end
      end
    end
  end
end
