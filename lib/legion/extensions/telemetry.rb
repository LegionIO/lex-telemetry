# frozen_string_literal: true

require 'legion/extensions/telemetry/version'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/helpers/scrubber'
require 'legion/extensions/telemetry/parsers/base'
require 'legion/extensions/telemetry/parsers/claude_code'
require 'legion/extensions/telemetry/helpers/event_store'
require 'legion/extensions/telemetry/helpers/stats'
require 'legion/extensions/telemetry/helpers/high_water_mark'
require 'legion/extensions/telemetry/runners/telemetry'

module Legion
  module Extensions
    module Telemetry
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
