# frozen_string_literal: true

require 'legion/extensions/telemetry/version'
require 'legion/extensions/telemetry/helpers/telemetry_event'
require 'legion/extensions/telemetry/helpers/scrubber'

module Legion
  module Extensions
    module Telemetry
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
