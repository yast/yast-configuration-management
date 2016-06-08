require "yast"

module Yast
  module SCM
    # This class handles the general bit of configuring/running SCM systems.
    class Provisioner
      include Yast::Logger

      # @return [String] Master server hostname
      attr_reader :master
      # @return [Integer] Number of authentication retries
      attr_reader :auth_retries
      # @return [Integer] Authentication timeout for each retry
      attr_reader :auth_timeout

      class << self
        # Current provisioner
        #
        # @return [Yast::SCM::Provisioner] Current provisioner
        def current
          @current
        end

        # Set the provisioner to be used
        #
        # @param provisioner [Yast::SCM::Provisioner] Provisioner to be used
        # @return [Yast::SCM::Provisioner] Current provisioner
        def current=(provisioner)
          @current = provisioner
        end

        # Return the provisioner for a given SCM system and a configuration
        #
        # @param type   [String] SCM type ("salt", "puppet", etc.)
        # @param config [Hash]   Provisioner configuration
        # @return [Yast::SCM::Provisioner] Provisioner to handle 'type' configuration
        #
        # @see .provisioner_class
        def provisioner_for(type, config)
          provisioner_class(type).new(config)
        end

        # Return the provisioner class to handle a given SCM system
        #
        # It tries to find the definition.
        #
        # @param type [String] SCM type ("salt", "puppet", etc.)
        # @return [Class] Provisioner class
        def provisioner_class(type)
          require "scm/#{type}_provisioner"
          Yast::SCM.const_get "#{type.capitalize}Provisioner"
        rescue NameError, LoadError
          raise "Provisioner for '#{type}' not found"
        end
      end

      # Constructor
      #
      # @param config [Hash] options
      # @option config [Integer] :master       Master server's name
      # @option config [Integer] :auth_retries Number of authentication retries
      # @option config [Integer] :auth_timeout Authentication timeout for each retry
      def initialize(config = {})
        log.info "Initializing provisioner #{self.class.name} with #{config}"
        @master       = config[:master]
        @auth_retries = config[:auth_retries] || 3
        @auth_timeout = config[:auth_timeout] || 10
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

      # Apply the configuration
      #
      # @see update_config_file
      # @see apply
      def run
        update_configuration
        apply
      end

    private

      # Apply the configuration using the SCM system
      #
      # It performs 'auth_retries' attempts. Descending classes should
      # implement #try_to_apply.
      #
      # @return [Boolean] true if the configuration was applied; false otherwise.
      def apply
        auth_retries.times do |i|
          log.info "Applying configuration (try #{i + 1}/#{auth_retries})"
          return true if try_to_apply
        end
        false
      end

      # Update SCM system configuration
      #
      # To be defined by descending classes.
      def update_configuration
        raise NotImplementedError
      end

      # Try to apply system configuration
      #
      # To be defined by descending classes.
      def try_to_apply
        raise NotImplementedError
      end
    end
  end
end
