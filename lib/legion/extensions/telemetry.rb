# frozen_string_literal: true

require 'legion/extensions/telemetry/version'

module Legion
  module Extensions
    module Telemetry
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
