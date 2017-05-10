require "cfa/base_model"
require "cfa/matcher"
require "configuration_management/cfa/yaml_parser"

module Yast
  module ConfigurationManagement
    module CFA
      # Represents a Salt Minion configuration file.
      class Minion < ::CFA::BaseModel
        # Configuration parser
        PARSER = Yast::ConfigurationManagement::CFA::YAMLParser.new
        # Path to configuration file
        PATH = "/etc/salt/minion.d/yast-configuration-management.conf".freeze

        # Constructor
        #
        # @param file_handler [.read, .write, nil] an object able to read/write a string.
        def initialize(file_handler: nil)
          super(PARSER, PATH, file_handler: file_handler)
        end

        # Set the master hostname
        #
        # @param hostname [String] Hostname
        def master=(hostname)
          data["master"] = hostname
        end

        # Return the master hostname if set
        #
        # @return [String,nil] Hostname
        def master
          data["master"]
        end

        # Set file roots for a given environment
        def set_file_roots(roots, env = "base")
          self.data ||= {}
          data["file_roots"] ||= {}
          data["file_roots"][env] = roots.map(&:to_s)
        end

        # Get file roots for a given environment
        def file_roots(env)
          data.fetch("file_roots", {}).fetch(env, [])
        end

        # Save the configuration file
        #
        # The directory/file are created if they not exist.
        #
        # @see create_directory_if_needed
        def save
          create_directory_if_needed
          super
        end

        # Determine whether the configuration file exists or not
        #
        # @return [Boolean] true if the file exists; false otherwise.
        def exist?
          File.exist?(@file_path)
        end

      private

        # Create the parent directory if it does not exist
        def create_directory_if_needed
          dirname = File.dirname(@file_path)
          return if Yast::FileUtils.Exists(dirname)
          SCR.Execute(Yast::Path.new(".target.mkdir"), dirname)
        end
      end
    end
  end
end
