require "yaml"

module Y2ConfigurationManagement
  module CFA
    # Represents a top.sls for Salt
    #
    # FIXME: this class it's not really a "CFA" one. It uses YAML
    # and it does respect comments and other stuff. It exists because
    # Augeas support for YAML is limited and it does not handle
    # multiple nesting levels.
    class SaltTop
      attr_accessor :path
      attr_accessor :data

      # Constructor
      #
      # @param path [Pathname] Path to the top file
      def initialize(path:)
        @path = path
      end

      def load
        self.data = File.exist?(path) ? YAML.load_file(path) : {}
      end

      def save
        File.open(path, "w+") { |f| f.puts YAML.dump(data) }
      end

      def add_states(states, env = "base")
        self.data ||= {}
        data[env] ||= {}
        data[env]["*"] = (data[env].fetch("*", []) + states).uniq
      end

      def states(env)
        data.fetch(env, {}).fetch("*", [])
      end
    end
  end
end
