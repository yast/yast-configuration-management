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
        attr_reader :config_url
        # @return [Integer] Number of authentication retries
        attr_reader :attempts
        # @return [Integer] Authentication timeout for each retry
        attr_reader :timeout
        # @return [URI,nil] Keys URL
        attr_reader :keys_url

        # Mode could not be determined because master and config_url are
        # both nil.
        class CouldNotDetermineMode < StandardError; end
        # Configuration (specified via config_url) could not be fetched
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
        # @option config [Integer] :master   Master server's name
        # @option config [Integer] :attempts Number of authentication retries
        # @option config [Integer] :timeout  Authentication timeout for each retry
        # @option config [Integer] :mode     Operation mode (:client or :masterless)
        def initialize(config = {})
          log.info "Initializing configurator #{self.class.name} with #{config}"
          @master     = config[:master]
          @attempts   = config[:attempts] || 3
          @timeout    = config[:timeout] || 10
          @config_url = config[:config_url].is_a?(::String) ? URI(config[:config_url]) : nil
          @keys_url   = config[:keys_url].is_a?(::String) ? URI(config[:keys_url]) : nil
          @mode       = config[:mode]
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
        # Work is delegated to methods called after the mode: #prepare_masterless_mode
        # and #prepare_client_mode.
        #
        # @see prepare_masterless_mode
        # @see prepare_client_mode
        def prepare
          send("prepare_#{mode}_mode")
        end

        # Determines whether the configurator is operating in the given module
        #
        # @return [Boolean] true if it's operating in the given mode; false otherwise.
        def mode?(value)
          mode == value
        end

        # Command to uncompress configuration
        UNCOMPRESS_CONFIG = "tar xf %<config_file>s -C %<config_tmpdir>s".freeze
        # Local file name of fetched configuration
        CONFIG_LOCAL_FILENAME = "config.tgz".freeze

        # Fetchs configuration from config_url
        #
        # FIXME: this code should be in another class. We want to extend this
        # mechanism to support, for example, git repositories.
        #
        # @return [Boolean] true if configuration was fetched; false otherwise.
        def fetch_config
          config_file = config_tmpdir.join(CONFIG_LOCAL_FILENAME)
          return false unless FileFromUrlWrapper.get_file(config_url, config_file)
          Yast::Execute.locally("tar", "xf", config_file.to_s, "-C", config_tmpdir.to_s)
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
        # Just fetch the configuration from the given #config_url
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
          update_configuration
        end

      private

        # Update CM system configuration
        #
        # To be defined by descending classes.
        def update_configuration
          raise NotImplementedError
        end

        # Return a path to a temporal directory to extract configuration
        #
        # @return [Pathname] Path name to the temporal directory
        def config_tmpdir
          @config_tmpdir ||= Pathname.new(Dir.mktmpdir)
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
