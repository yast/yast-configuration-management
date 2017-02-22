require "yaml"
require "pathname"
require "tmpdir"

module Yast
  module CM
    module Configurations
      # This class inteprets the module configuration
      class Base
        # Default location of the module configuration
        DEFAULT_PATH = Pathname.new("/var/adm/autoinstall/cm.yml")
        # Default value for auth_attempts
        DEFAULT_AUTH_ATTEMPTS = 3
        # Defaull value for auth_time_out
        DEFAULT_AUTH_TIME_OUT = 15

        # @return [String] Provisioner type ("salt" and "puppet" are supported)
        attr_reader :type
        # @return [:client, :masterless] Operation mode
        attr_reader :mode
        # @return [String,nil] Master server hostname
        attr_reader :master
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
          # @return [Pathname] File path
          # @return [Config] Configuration
          #
          # @see DEFAULT_PATH
          def load(path = DEFAULT_PATH)
            return false unless path.exist?
            content = YAML.load_file(path)
            class_for(content[:type]).new(content)
          end

          def for(config)
            class_for(config["type"]).new(config)
          end

          def class_for(type)
            require "cm/configurations/#{type}"
            Yast::CM::Configurations.const_get type.capitalize
          rescue NameError, LoadError
            raise "Configuration handler for '#{type}' not found"
          end
        end

        def initialize(options)
          symbolized_opts = Hash[options.map { |k, v| [k.to_sym, v] }]
          @master           = symbolized_opts[:master]
          @mode             = @master ? :client : :masterless
          @work_dir         = symbolized_opts[:work_dir]
          @keys_url         = symbolized_opts[:keys_url]
          @auth_attempts    = symbolized_opts[:auth_attempts] || DEFAULT_AUTH_ATTEMPTS
          @auth_time_out    = symbolized_opts[:auth_time_out] || DEFAULT_AUTH_TIME_OUT
          post_initialize(symbolized_opts)
        end

        def post_initialize(_options)
          nil
        end

        # Return an array of exportable attributes
        #
        # @return [Array<Symbol>] Attribute names
        def attributes
          @attributes ||= %i(type mode master auth_attempts auth_time_out keys_url work_dir)
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
          attributes.each_with_object({}) do |key, memo|
            value = send(key)
            memo[key] = value unless value.nil?
          end
        end

        # Return configuration values in a hash but filtering sensible information
        #
        # @return [Hash] Configuration values filtering sensible information.
        def to_secure_hash
          to_hash.reject { |k| k.to_s.end_with?("_url") }
        end

        # Return a path to a temporal directory to extract states/pillars
        #
        # @return [String] Path name to the temporal directory
        def work_dir
          @work_dir ||= Pathname(Dir.mktmpdir)
        end
      end
    end
  end
end
