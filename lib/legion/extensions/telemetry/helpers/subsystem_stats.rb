# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Helpers
        module SubsystemStats
          module_function

          def collect_transport
            return nil unless Legion.const_defined?(:Transport, false)

            stats = {}

            if Legion::Transport.respond_to?(:connection) && Legion::Transport.connection.respond_to?(:status)
              stats[:connection_status] = Legion::Transport.connection.status.to_s
            end

            if Legion::Transport.respond_to?(:connection) && Legion::Transport.connection.respond_to?(:channel_max)
              stats[:channel_max] = Legion::Transport.connection.channel_max
            end

            stats
          rescue StandardError => _e
            nil
          end

          def collect_cache
            return nil unless defined?(Legion::Cache)

            stats = {}

            if Legion::Cache.respond_to?(:stats)
              raw = Legion::Cache.stats
              stats.merge!(raw) if raw.is_a?(Hash)
            end

            stats
          rescue StandardError => _e
            nil
          end

          def collect_data
            return nil unless defined?(Legion::Data)

            stats = {}

            stats[:connected] = Legion::Data.connected? if Legion::Data.respond_to?(:connected?)

            stats[:pool_size] = Legion::Data::Pool.size if defined?(Legion::Data::Pool) && Legion::Data::Pool.respond_to?(:size)

            stats
          rescue StandardError => _e
            nil
          end

          def collect_llm
            return nil unless defined?(Legion::LLM)

            stats = {}

            if Legion::LLM.respond_to?(:pipeline_stats)
              raw = Legion::LLM.pipeline_stats
              stats.merge!(raw) if raw.is_a?(Hash)
            end

            stats
          rescue StandardError => _e
            nil
          end

          def collect_extensions
            return nil unless defined?(Legion::Extensions)

            stats = {}

            if Legion::Extensions.respond_to?(:loaded)
              loaded = Legion::Extensions.loaded
              stats[:loaded_count] = loaded.is_a?(Array) ? loaded.length : loaded.to_i
            end

            stats
          rescue StandardError => _e
            nil
          end

          def collect_gaia
            return nil unless defined?(Legion::Gaia)

            stats = {}

            stats[:tick_count] = Legion::Gaia.tick_count if Legion::Gaia.respond_to?(:tick_count)

            stats[:active_phase] = Legion::Gaia.active_phase.to_s if Legion::Gaia.respond_to?(:active_phase)

            stats
          rescue StandardError => _e
            nil
          end
        end
      end
    end
  end
end
