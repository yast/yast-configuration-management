require "yaml"
require "pathname"
require "tmpdir"

module Yast
  module CM
    # This class inteprets the module configuration
    class Config
      # Default location of the module configuration
      DEFAULT_PATH = Pathname.new("/var/adm/autoinstall/cm.yml")
      # Supported provisioner types
      TYPES = ["salt", "puppet"].freeze
      # Attributes to include when exporting to a hash
      ATTRIBUTES = %i(type mode master auth_attempts auth_time_out definitions_url keys_url definitions_root).freeze

      # @return [String] Provisioner type (only "salt" and "puppet" are supported)
      attr_reader :type
      # @return [:client, :masterless] Operation mode
      attr_reader :mode
      # @return [String,nil] Master server hostname
      attr_reader :master
      # @return [URI,nil] System definition URL (states, recipes, etc.)
      attr_reader :definitions_url
      # @return [Integer] Number of authentication attempts
      attr_reader :auth_attempts
      # @return [Integer] Authentication time out for each authentication attempt
      attr_reader :auth_time_out
      # @return [URI,nil] Keys URL
      attr_reader :keys_url

      class << self
        # Load configuration from a file
        #
        # If not specified, the DEFAULT_PATH is used.
        #
        # @return [Config] Configuration
        # @see DEFAULT_PATH
        def load(path = DEFAULT_PATH)
          return false unless Pathname(path).exist?
          new(YAML.load_file(path))
        end
      end

      # Constructor
      #
      # TODO: validations:
      # * master or definitions_url should be specified
      def initialize(options)
        symbolized_opts = Hash[options.map { |k, v| [k.to_sym, v] }]
        @type             = symbolized_opts[:type].nil? ? "salt" : symbolized_opts[:type].downcase
        @master           = symbolized_opts[:master]
        @mode             = @master ? :client : :masterless
        @definitions_url  = symbolized_opts[:definitions_url]
        @definitions_root = symbolized_opts[:definitions_root]
        @keys_url         = symbolized_opts[:keys_url]
        @auth_attempts    = symbolized_opts[:auth_attempts]
        @auth_time_out    = symbolized_opts[:auth_time_out]
      end

      # Save configuration to the given file
      #
      # @param path [Pathname] Path to file
      def save(path = DEFAULT_PATH)
        File.open(path, "w+") { |f| f.puts to_secure_hash.to_yaml }
      end

      # Return configuration values in a hash
      #
      # @return [Hash] Configuration values
      def to_hash
        ATTRIBUTES.each_with_object({}) do |key, memo|
          value = send(key)
          memo[key] = value unless value.nil?
        end
      end

      # Return configuration filtering sensible information
      #
      # @return [Hash] Configuration values filtering sensible information.
      def to_secure_hash
        to_hash.reject { |k| k.to_s.end_with?("_url") }
      end

      # Return a path to a temporal directory to extract configuration
      #
      # @return [String] Path name to the temporal directory
      def definitions_root
        @definitions_root ||= Dir.mktmpdir
      end
    end
  end
end
