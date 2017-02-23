require "yast"
require "uri"
require "transfer/file_from_url"
require "pathname"
require "yast2/execute"
require "cm/key_finder"
require "cm/file_from_url_wrapper"

module Yast
  module CM
    # This class handles the general bit of configuring/running CM systems.
    module Configurators
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
          # Commands are defined as classes in the Yast::CM::Commands namespace
          #
          # @return [Object] Commands return value
          #
          # @see Yast::CM::Commands namespace
          def command(name, *args)
            Yast::CM::Commands::Base.find(name).run(*args)
          end
        end

        class << self
          # Current configurator
          #
          # @return [Yast::CM::Configurators::Base] Current configurator
          def current
            @current
          end

          # Set the configurator to use
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
            require "cm/configurators/#{type}"
            Yast::CM::Configurators.const_get type.capitalize
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

        # Prepare the system to run the provisioner
        #
        # Configuration is updated and, after that, the work is delegated to methods
        # called after the mode: #prepare_masterless_mode and #prepare_client_mode.
        #
        # @see prepare_masterless_mode
        # @see prepare_client_mode
        def prepare
          send("prepare_#{config.mode}")
        end

        # Determines whether the configurator is operating in the given module
        #
        # @return [Boolean] true if it's operating in the given mode; false otherwise.
        def mode?(value)
          mode == value
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
end
