# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Helpers
        module Scrubber
          TOOL_WHITELIST = {
            'Read'  => %i[file_path offset limit],
            'Write' => %i[file_path],
            'Edit'  => %i[file_path],
            'Glob'  => %i[pattern path],
            'Grep'  => %i[pattern path include],
            'Bash'  => %i[description timeout],
            'Agent' => %i[description subagent_type]
          }.freeze

          PII_PATTERNS = {
            /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/     => '[EMAIL]',
            /\b\d{3}-\d{2}-\d{4}\b/                                   => '[SSN]',
            /\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b/ => '[PHONE]'
          }.freeze

          PARANOID_KEEP = %i[event_type tool_name timestamp tokens session_id source].freeze

          module_function

          def scrub(event:, level: :standard)
            scrubbed = event.dup

            case level
            when :minimal
              scrub_pii(scrubbed)
            when :standard
              scrub_tool_input(scrubbed)
              scrub_pii(scrubbed)
            when :paranoid
              scrub_paranoid(scrubbed)
            end

            scrubbed
          end

          def scrub_tool_input(event)
            return unless event[:tool_input].is_a?(Hash)

            whitelist = TOOL_WHITELIST[event[:tool_name]]
            unless whitelist
              event[:tool_input] = nil
              return
            end

            event[:tool_input] = event[:tool_input].slice(*whitelist)
          end

          def scrub_pii(event)
            return unless event[:tool_input].is_a?(Hash)

            event[:tool_input] = event[:tool_input].transform_values { |v| scrub_pii_value(v) }
          end

          def scrub_pii_value(value)
            return value unless value.is_a?(String)

            PII_PATTERNS.each do |pattern, replacement|
              value = value.gsub(pattern, replacement)
            end
            value
          end

          def scrub_paranoid(event)
            event[:tool_input] = nil
            event[:error] = nil
            event[:metadata] = nil
            event.delete_if { |k, _| !PARANOID_KEEP.include?(k) }
          end
        end
      end
    end
  end
end
