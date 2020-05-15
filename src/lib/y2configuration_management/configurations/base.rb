require "yaml"
require "pathname"
require "tmpdir"
require "uri"

Yast.import "Installation"
Yast.import "Directory"

module Y2ConfigurationManagement
  # This module provides the classes to process the configuration
  #
  # These classes are responsible for processing and storing the configuration
  # to be used by the provisioners (Salt or Puppet). They keep information about
  # the operation mode, the server hostname, the number of attempts, timeouts,
  # etc.
  #
  # The common settings and behaviour are implemented in the {Base} class.
  # {Salt} and {Puppet} classes extend it in order to provide the specific
  # bits for each provisioner.
  module Configurations
    # This class implements the current behaviour for configuration classes
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
        # It saves the configuration that can be retrieved later by calling to the
        # {.current} method.
        #
        # @param hash [Hash<String,Object>] Settings from a profile or a control file
        def import(hash)
          self.current = from_hash(hash)
        end

        # Returns a configuration according to the given hash
        #
        # @param hash [Hash] Configuration management settings
        # @return [Base] Returns the configuration. It uses the `:type` key to determine its type.
        def from_hash(hash)
          klass = class_for(hash["type"])
          klass.new_from_hash(hash)
        end

        # Returns a configuration according to the given hash
        #
        # Dervide classes may redefined this method.
        #
        # @param hash [Hash] Configuration management setting
        # @return [Base] Configuration instance
        def new_from_hash(hash)
          options = Hash[hash.map { |k, v| [k.to_sym, v] }]
          new(options)
        end

        def class_for(type)
          require "y2configuration_management/configurations/#{type}"
          Y2ConfigurationManagement::Configurations.const_get type.capitalize
        rescue NameError, LoadError
          raise "Configuration handler for '#{type}' not found"
        end
      end

      # Constructor
      #
      # Derived classes override the {#post_initialize} method to handle additional options.
      #
      # @param options [Hash<Symbol,Object>] Options
      # @option options [String,nil] master Master server
      # @option options [String] :keys_url Authentication keys URL
      # @option options [Integer] :auth_attempts Authentication attempts
      # @option options [Integer] :auth_time_out Authentication timeout for each attempt
      # @option options [Boolean] :enable_services Whether to enable the provisioner service
      def initialize(options = {})
        @master          = options[:master]
        @mode            = @master ? :client : :masterless
        @keys_url        = URI(options[:keys_url]) if options[:keys_url]
        @auth_attempts   = options[:auth_attempts] || DEFAULT_AUTH_ATTEMPTS
        @auth_time_out   = options[:auth_time_out] || DEFAULT_AUTH_TIME_OUT
        @enable_services = options[:enable_services] || true
        post_initialize(options)
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
        prefix = (scope == :target) ? "/" : Yast::Installation.destdir
        Pathname.new(prefix).join(@work_dir)
      end

    private

      # Build a path to be used as work_dir
      #
      # @return [Pathname] Relative work_dir path
      def build_work_dir_name
        path = Pathname.new(Yast::Directory.vardir).join("cm-#{Time.now.strftime("%Y%m%d%H%M")}")
        path.relative_path_from(Pathname.new("/"))
      end
    end
  end
end
