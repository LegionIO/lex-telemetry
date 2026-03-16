# frozen_string_literal: true

module Legion
  module Extensions
    module Telemetry
      module Parsers
        module Base
          def source_name
            raise NotImplementedError
          end

          def can_parse?(_path)
            raise NotImplementedError
          end

          def parse(_path, offset: 0, &_block)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
