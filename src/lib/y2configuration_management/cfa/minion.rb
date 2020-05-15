require "cfa/base_model"
require "cfa/matcher"
require "y2configuration_management/cfa/yaml_parser"

Yast.import "FileUtils"

module Y2ConfigurationManagement
  module CFA
    # Represents a Salt Minion configuration file.
    class Minion < ::CFA::BaseModel
      # Configuration parser
      PARSER = Y2ConfigurationManagement::CFA::YAMLParser.new
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
      #
      # @param roots [Array<String>] Names of the directories to be used as `file_roots`
      # @param env [String] Environment name (e.g., "base")
      def set_file_roots(roots, env = "base")
        set_array(:file_roots, roots, env)
      end

      # Set pillar roots for a given environment
      #
      # @param roots [Array<String>] Names of the directories to be used as `pillar_roots`
      # @param env [String] Environment name (e.g., "base")
      def set_pillar_roots(roots, env = "base")
        set_array(:pillar_roots, roots, env)
      end

      # Get file roots for a given environment
      #
      # @param env [String] Environment name (e.g., "base")
      def file_roots(env)
        data.fetch("file_roots", {}).fetch(env, [])
      end

      # Get pillar roots for a given environment
      #
      # @param env [String] Environment name (e.g., "base")
      def pillar_roots(env)
        data.fetch("pillar_roots", {}).fetch(env, [])
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
        Yast::SCR.Execute(Yast::Path.new(".target.mkdir"), dirname)
      end

      # Sets an array-like value for a given key
      #
      # @param key [String,Symbol] Key name
      # @param items [Array<#to_s>] List of elements to include
      # @param env [String] Environment name (e.g., "base")
      def set_array(key, items, env = "base")
        self.data ||= {}
        key = key.to_s
        data[key] ||= {}
        data[key][env] = items.map(&:to_s)
      end
    end
  end
end
