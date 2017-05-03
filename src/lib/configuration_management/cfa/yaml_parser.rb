require "yaml"

module Yast
  module ConfigurationManagement
    module CFA
      # Simple YAML parser for CFA
      class YAMLParser
        def parse(raw_string)
          YAML.load(raw_string)
        end

        def serialize(data)
          YAML.dump(data)
        end

        def empty
          {}
        end
      end
    end
  end
end
