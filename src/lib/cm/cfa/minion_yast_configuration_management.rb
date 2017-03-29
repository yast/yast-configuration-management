require "yaml"

module Yast
  module CM
    module CFA
      # Represents a YaST Salt Minion configuration file in /etc/salt/minion.d/
      #
      class MinionYastConfigurationManagement
        # Path to configuration file
        PATH = "/etc/salt/minion.d/yast-configuration-management.conf".freeze

        attr_accessor :path
        attr_accessor :data

        # Constructor
        #
        # @param file_handler [.read, .write, nil] an object able to read/write a string.
        def initialize(path: PATH)
          @path = path
        end

        def load
          self.data = File.exist?(path) ? YAML.load_file(path) : {}
        end

        def save
          File.open(path, "w+") { |f| f.puts YAML.dump(data) }
        end

        def set_file_roots(roots, env = "base")
          self.data ||= {}
          data["file_roots"] ||= {}
          data["file_roots"][env] = roots.map(&:to_s)
        end

        def file_roots(env)
          data.fetch("file_roots", {}).fetch(env, [])
        end
      end
    end
  end
end
