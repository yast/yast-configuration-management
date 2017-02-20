require "yaml"
require "pathname"

module Yast
  module CM
    # This class inteprets the module configuration
    class Config
      # Default location of the module configuration
      DEFAULT_PATH = Pathname.new("/var/adm/autoinstall/cm.yml")
      # Supported provisioner types
      TYPES = ["salt", "puppet"].freeze

      # @return [String] Provisioner type (only "salt" and "puppet" are supported)
      attr_reader :type
      # @return [:client, :masterless] Operation mode
      attr_reader :mode
      # @return [String,nil] Master server hostname
      attr_reader :master
      # @return [URI,nil] Config URL
      attr_reader :config_url
      # @return [Integer] Number of authentication retries
      attr_reader :attempts
      # @return [Integer] Authentication timeout for each retry
      attr_reader :timeout
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
      # * master or config_url should be specified
      def initialize(options)
        symbolized_opts = Hash[options.map { |k,v| [k.to_sym, v] }]
        @type       = symbolized_opts[:type].nil? ? "salt" : symbolized_opts[:type].downcase
        @master     = symbolized_opts[:master]
        @mode       = @master ? :client : :masterless
        @config_url = symbolized_opts[:config_url]
        @keys_url   = symbolized_opts[:keys_url]
        @attempts   = symbolized_opts[:attempts]
        @timeout    = symbolized_opts[:timeout]
      end

      # Save configuration to the given file
      #
      # @param path [Pathname] Path to file
      def save(path = DEFAULT_PATH)
        File.open(path, "w+") { |f| f.puts to_yaml }
      end

      # Return configuration values in a hash
      #
      # @return [Hash] Configuration values
      def to_hash
        %i(type mode master attempts timeout config_url keys_url).each_with_object({}) do |key, memo|
          value = send(key)
          memo[key] = value unless value.nil?
        end
      end

      # Return configuration values in a YAML string
      #
      # @return [String] YAML representation of configuraton values
      def to_yaml
        to_hash.to_yaml
      end
    end
  end
end
