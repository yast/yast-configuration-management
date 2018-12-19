require "yaml"
require "pathname"
require "tmpdir"
require "uri"

Yast.import "Installation"
Yast.import "Directory"

module Yast
  module ConfigurationManagement
    module Configurations
      # This class inteprets the module configuration
      class Base
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
        # @return [Boolean] CM Services will be enabled on the target system
        attr_reader :enable_services

        class << self
          # @return [Base] Current configuration
          attr_accessor :current

          # Import settings from an AutoYaST profile
          #
          # @param profile [Hash] Configuration management settings from profile
          def import(profile)
            self.current = self.for(profile)
          end

          def for(config)
            class_for(config["type"]).new(config)
          end

          def class_for(type)
            require "configuration_management/configurations/#{type}"
            Yast::ConfigurationManagement::Configurations.const_get type.capitalize
          rescue NameError, LoadError
            raise "Configuration handler for '#{type}' not found"
          end
        end

        def initialize(options)
          symbolized_opts = Hash[options.map { |k, v| [k.to_sym, v] }]
          @master           = symbolized_opts[:master]
          @mode             = @master ? :client : :masterless
          @keys_url         = URI(symbolized_opts[:keys_url]) if symbolized_opts[:keys_url]
          @auth_attempts    = symbolized_opts[:auth_attempts] || DEFAULT_AUTH_ATTEMPTS
          @auth_time_out    = symbolized_opts[:auth_time_out] || DEFAULT_AUTH_TIME_OUT
          @enable_services  = symbolized_opts[:enable_services] || true
          post_initialize(symbolized_opts)
        end

        # Hook to run after initializing the instance
        #
        # This method is supposed to be overwritten by configuration classes if needed.
        #
        # @param _options [Hash] Configuration options
        def post_initialize(_options)
          nil
        end

        # Return a path to a temporal directory to extract states/pillars
        #
        # @param scope [Symbol] Path relative to inst-sys (:local) or the target system (:target)
        # @return [String] Path name to the temporal directory
        def work_dir(scope = :local)
          @work_dir ||= build_work_dir_name
          prefix = (scope == :target) ? "/" : Installation.destdir
          Pathname.new(prefix).join(@work_dir)
        end

      private

        # Build a path to be used as work_dir
        #
        # @return [Pathname] Relative work_dir path
        def build_work_dir_name
          path = Pathname.new(Directory.vardir).join("cm-#{Time.now.strftime("%Y%m%d%H%M")}")
          path.relative_path_from(Pathname.new("/"))
        end
      end
    end
  end
end
