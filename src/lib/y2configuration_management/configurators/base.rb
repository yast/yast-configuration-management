require "yast"
require "uri"
require "transfer/file_from_url"
require "pathname"
require "yast2/execute"
require "y2configuration_management/key_finder"
require "y2configuration_management/file_from_url_wrapper"

Yast.import "WFM"
Yast.import "Installation"

module Y2ConfigurationManagement
  module Configurators
    # This class handles the general bits of configuring/running CM systems.
    #
    # Configurators are responsible for setting up a given configuration management system.
    # They usually take care of downloading assets and/or adjusting the configuration files.
    class Base
      include Yast::Logger

      # @return [Configurations::Salt] Configuration object
      attr_reader :config

      class << self
        # Method to define modes
        #
        # @param mode [Symbol] Operation mode (:client, :masterless)
        # @param block [Proc]] Code to execute in the given module
        def mode(mode, &block)
          define_method("prepare_#{mode}", block)
        end

        # Run a command
        #
        # Commands are defined as classes in the Y2ConfigurationManagement::Commands namespace
        #
        # @return [Object] Commands return value
        #
        # @see Y2ConfigurationManagement::Commands namespace
        def command(name, *args)
          Y2ConfigurationManagement::Commands::Base.find(name).run(*args)
        end

        # Current configurator
        #
        # @return [Y2ConfigurationManagement::Configurators::Base] Current configurator
        attr_reader :current

        # Set the configurator to use
        #
        # @return [Y2ConfigurationManagement::Configurators::Base]
        #   Current configurator
        attr_writer :current

        # Return the configurator for a given CM system and a configuration
        #
        # @param config [Hash]   Configurator configuration
        # @return [Y2ConfigurationManagement::Configurators::Base]
        #   Configurator to handle 'type' configuration
        #
        # @see .class_for
        def for(config)
          class_for(config.type).new(config)
        end

        # Return the configurator class to handle a given CM system
        #
        # It tries to find the definition.
        #
        # @param type [String] CM type ("salt", "puppet", etc.)
        # @return [Class] Configurator class
        def class_for(type)
          require "y2configuration_management/configurators/#{type}"
          Y2ConfigurationManagement::Configurators.const_get type.capitalize
        rescue NameError, LoadError
          raise "Configurator for '#{type}' not found"
        end
      end

      # Constructor
      #
      # @param config [Configurations::Salt] Configuration object
      def initialize(config)
        log.info "Initializing configurator #{self.class.name}"
        @config = config
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

      # Return a list of services which have to be enabled
      #
      # @return [[Array<String>] List of services
      def services
        []
      end

      # Prepare the system to run the provisioner
      #
      # Work directory is created (only in :client mode) and, after that, the
      # control is passed to the required configurator. See mode definitions
      # in the given configurator.
      #
      # @param opts [Hash] Configurator options
      # @see .mode
      def prepare(opts = {})
        ::FileUtils.mkdir_p(config.work_dir) if mode?(:masterless)
        send("prepare_#{config.mode}", opts)
      end

      # Determines whether the configurator is operating in the given module
      #
      # @return [Boolean] true if it's operating in the given mode; false otherwise.
      def mode?(value)
        config.mode == value
      end

      # Local file name of fetched configuration
      CONFIG_LOCAL_FILENAME = "config.tgz".freeze

      # Fetchs CM configuration (states, recipes, etc.)
      #
      # FIXME: this code should be in another class. We want to extend this
      # mechanism to support, for example, git repositories.
      #
      # @return [Boolean] true if configuration was fetched; false otherwise.
      def fetch_config(url, target)
        config_file = target.join(CONFIG_LOCAL_FILENAME)
        return false unless FileFromUrlWrapper.get_file(url, config_file)
        Yast::Execute.locally("tar", "xf", config_file.to_s, "-C", target.to_s)
      end

      # Fetch keys
      #
      # Fetch keys to perform authentication
      #
      # @param url [URI] Base URL to search the keys
      # @param private_key_path [Pathname] Path to private key
      # @param public_key_path  [Pathname] Path to public key
      def fetch_keys(url, private_key_path, public_key_path)
        return false if url.nil? # FIXME: should be move to the caller
        KeyFinder.new(keys_url: url).fetch_to(private_key_path, public_key_path)
      end
    end
  end
end
