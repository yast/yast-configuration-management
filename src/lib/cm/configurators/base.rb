require "yast"
require "uri"
require "transfer/file_from_url"
require "pathname"
require "yast2/execute"
require "tmpdir"
require "cm/key_finder"
require "cm/file_from_url_wrapper"

module Yast
  module CM
    # This class handles the general bit of configuring/running CM systems.
    module Configurators
      class Base
        include Yast::Logger

        # @return [Symbol] Operation mode (:client or :masterless)
        attr_reader :mode
        # @return [String,nil] Master server hostname
        attr_reader :master
        # @return [URI,nil] Config URL
        attr_reader :definitions_url
        # @return [Integer] Number of authentication attempts
        attr_reader :auth_attempts
        # @return [Integer] Authentication time out for each attempt
        attr_reader :auth_time_out
        # @return [URI,nil] Authentication keys URL
        attr_reader :keys_url
        # @return [Pathname] Configuration directory for masterless mode
        attr_reader :definitions_root

        # Mode could not be determined because master and definitions_url are
        # both nil.
        class CouldNotDetermineMode < StandardError; end
        # Configuration (specified via definitions_url) could not be fetched
        class ConfigurationNotFetched < StandardError; end

        class << self
          # Current configurator
          #
          # @return [Yast::CM::Configurators::Base] Current configurator
          def current
            @current
          end

          # Set the configurator to be used
          #
          # @param configurator [Yast::CM::Configurators::Base] Configurator to be used
          # @return [Yast::CM::Configurators::Base] Current configurator
          def current=(configurator)
            @current = configurator
          end

          # Return the configurator for a given CM system and a configuration
          #
          # @param type   [String] CM type ("salt", "puppet", etc.)
          # @param config [Hash]   Configurator configuration
          # @return [Yast::CM::Configurators::Base] Configurator to handle 'type' configuration
          #
          # @see .configurator_class
          def configurator_for(config)
            configurator_class(config.type).new(config.to_hash)
          end

          # Return the configurator class to handle a given CM system
          #
          # It tries to find the definition.
          #
          # @param type [String] CM type ("salt", "puppet", etc.)
          # @return [Class] Configurator class
          def configurator_class(type)
            require "cm/configurators/#{type}"
            Yast::CM::Configurators.const_get type.capitalize
          rescue NameError, LoadError
            raise "Configurator for '#{type}' not found"
          end
        end

        # Constructor
        #
        # @param config [Hash] options
        # @option config [Integer] :master           Master server's name
        # @option config [Integer] :auth_attempts    Number of authentication attempts
        # @option config [Integer] :auth_time_out    Authentication time out for each authentication attempt
        # @option config [Symbol]  :mode             Operation mode (:client or :masterless)
        # @option config [String]  :definitions_url  Definitions URL (states, recipes, etc.)
        # @option config [String]  :definitions_root masterless configuration directory
        # @option config [String]  :keys_url         Authentication keys URL
        def initialize(config = {})
          log.info "Initializing configurator #{self.class.name} with #{config}"
          @master           = config[:master]
          @auth_attempts    = config[:auth_attempts] || 3
          @auth_time_out    = config[:auth_time_out] || 10
          @definitions_url  = config[:definitions_url].is_a?(::String) ? URI(config[:definitions_url]) : nil
          @keys_url         = config[:keys_url].is_a?(::String) ? URI(config[:keys_url]) : nil
          @mode             = config[:mode]
          @definitions_root = Pathname.new(config[:definitions_root]) unless config[:definitions_root].nil?
        end

        # Return the list of packages to install
        #
        # @example List of packages to install
        #   configurator.packages #=> { "install" => ["pkg1", "pkg2"] }
        #
        # @example Lists of packages to install and remove
        #   configurator.packages #=> { "install" => ["pkg1", "pkg2"], "remove" => ["pkg3"] }
        #
        # @return [Hash] List of packages to install/remove
        def packages
          {}
        end

        # Prepare the system to run the provisioner
        #
        # Configuration is updated and, after that, the work is delegated to methods
        # called after the mode: #prepare_masterless_mode and #prepare_client_mode.
        #
        # @see prepare_masterless_mode
        # @see prepare_client_mode
        def prepare
          update_configuration
          send("prepare_#{mode}_mode")
        end

        # Determines whether the configurator is operating in the given module
        #
        # @return [Boolean] true if it's operating in the given mode; false otherwise.
        def mode?(value)
          mode == value
        end

        # Command to uncompress configuration
        UNCOMPRESS_CONFIG = "tar xf %<config_file>s -C %<definitions_root>s".freeze
        # Local file name of fetched configuration
        CONFIG_LOCAL_FILENAME = "config.tgz".freeze

        # Fetchs configuration from definitions_url
        #
        # FIXME: this code should be in another class. We want to extend this
        # mechanism to support, for example, git repositories.
        #
        # @return [Boolean] true if configuration was fetched; false otherwise.
        def fetch_config
          config_file = definitions_root.join(CONFIG_LOCAL_FILENAME)
          return false unless FileFromUrlWrapper.get_file(definitions_url, config_file)
          Yast::Execute.locally("tar", "xf", config_file.to_s, "-C", definitions_root.to_s)
        end

        # Fetch keys
        #
        # Fetch keys to perform authentication
        def fetch_keys
          return false if keys_url.nil?
          # FIXME: inject?
          KeyFinder.new(keys_url: keys_url)
                   .fetch_to(private_key_path, public_key_path)
        end

        # Prepare the system to run in masterless mode
        #
        # Just fetch the configuration from the given #definitions_url
        #
        # @return [Boolean] true if configuration suceeded; false otherwise.
        #
        # @see fetch_config
        # @see prepare
        def prepare_masterless_mode
          fetch_config
        end

        # Prepare the system to run in client mode
        #
        # * Update configuration file writing the master name
        # * Fetch the authentication public/private key
        #
        # @return [Boolean] true if configuration suceeded; false otherwise.
        #
        # @see fetch_keys
        # @see update_configuration
        def prepare_client_mode
          fetch_keys
        end

      private

        # Update CM system configuration
        #
        # To be defined by descending classes.
        def update_configuration
          raise NotImplementedError
        end

        # Return path to private key
        def private_key_path
          raise NotImplementedError
        end

        # Return path to public key
        def public_key_path
          raise NotImplementedError
        end
      end
    end
  end
end
