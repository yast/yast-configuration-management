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
    class Provisioner
      include Yast::Logger

      MODES = [:masterless, :client].freeze

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
        # Current provisioner
        #
        # @return [Yast::CM::Provisioner] Current provisioner
        def current
          @current
        end

        # Set the provisioner to be used
        #
        # @param provisioner [Yast::CM::Provisioner] Provisioner to be used
        # @return [Yast::CM::Provisioner] Current provisioner
        def current=(provisioner)
          @current = provisioner
        end

        # Return the provisioner for a given CM system and a configuration
        #
        # @param type   [String] CM type ("salt", "puppet", etc.)
        # @param config [Hash]   Provisioner configuration
        # @return [Yast::CM::Provisioner] Provisioner to handle 'type' configuration
        #
        # @see .provisioner_class
        def provisioner_for(type, config)
          provisioner_class(type).new(config)
        end

        # Return the provisioner class to handle a given CM system
        #
        # It tries to find the definition.
        #
        # @param type [String] CM type ("salt", "puppet", etc.)
        # @return [Class] Provisioner class
        def provisioner_class(type)
          require "cm/#{type}_provisioner"
          Yast::CM.const_get "#{type.capitalize}Provisioner"
        rescue NameError, LoadError
          raise "Provisioner for '#{type}' not found"
        end
      end

      # Constructor
      #
      # @param config [Hash] options
      # @option config [Integer] :master   Master server's name
      # @option config [Integer] :attempts Number of authentication retries
      # @option config [Integer] :timeout Authentication timeout for each retry
      def initialize(config = {})
        log.info "Initializing provisioner #{self.class.name} with #{config}"
        @master     = config[:master]
        @attempts   = config[:attempts] || 3
        @timeout    = config[:timeout] || 10
        @config_url = config[:config_url].is_a?(::String) ? URI(config[:config_url]) : nil
        @keys_url   = config[:keys_url].is_a?(::String) ? URI(config[:keys_url]) : nil
      end

      # Return the list of packages to install
      #
      # @example List of packages to install
      #   provider.packages #=> { "install" => ["pkg1", "pkg2"] }
      #
      # @example Lists of packages to install and remove
      #   provider.packages #=> { "install" => ["pkg1", "pkg2"], "remove" => ["pkg3"] }
      #
      # @return [Hash] List of packages to install/remove
      def packages
        {}
      end

      # Run the provisioner applying the configuration to the system
      #
      # Work is delegated to methods called after the mode: #run_masterless_mode
      # and #run_client_mode.
      #
      # @see run_masterless_mode
      # @see run_client_mode
      def run
        send("run_#{mode}_mode")
      end

      # Provisioner operation mode
      #
      # The mode is decided depending on 'master' and 'config_url'
      # values.
      #
      # * If 'master' is specified -> :client
      # * If 'config_url' is -> :masterless
      # * Otherwise -> :client
      #
      # @param proposed [String] Proposed mode
      # @return [Symbol] Mode. Possible values are listed in MODE constant.
      #
      # @see MODE
      def mode
        return @mode unless @mode.nil?
        @mode =
          if master || (master.nil? && config_url.nil?)
            :client
          else
            :masterless
          end
      end

      # Determines whether the provisioner is operating in the given module
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
        true
      rescue
        false
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

      # Run the provisioner in masterless mode
      #
      # * Fetch the configuration from the given #config_url
      # * Apply the configuration using masterless mode
      #
      # @return [Boolean] true if configuration suceeded; false otherwise.
      #
      # @see fetch_config
      # @see apply_masterless_mode
      def run_masterless_mode
        fetch_config && apply_masterless_mode
      end

      # Run the provisioner in client mode
      #
      # * Update configuration file writing the master name
      # * Run the provisioner
      #
      # @return [Boolean] true if configuration suceeded; false otherwise.
      #
      # @see update_configuration
      # @see apply
      def run_client_mode
        fetch_keys
        update_configuration && with_retries(attempts) { apply_client_mode }
      end

    private

      # Apply the configuration using the CM system
      #
      # To be redefined by inheriting classes.
      #
      # @return [Boolean] true if the configuration was applied; false otherwise.
      def apply_client_mode
        raise NotImplementedError
      end

      # Apply the configuration using the CM system
      #
      # Configuration is available at #config_tmpdir
      #
      # @return [Boolean] true if the configuration was applied; false otherwise.
      #
      # @see config_tmpdir
      def apply_masterless_mode
        raise NotImplementedError
      end

      def with_retries(attempts = 1)
        attempts.times do |i|
          log.info "Applying configuration (try #{i + 1}/#{attempts})"
          return true if yield
        end
        false
      end

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
