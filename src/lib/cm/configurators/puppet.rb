require "yast"
require "cheetah"
require "cm/cfa/puppet"
require "cm/configurators/base"
require "pathname"

module Yast
  module CM
    module Configurators
      # Puppet configurator
      #
      # This class is responsible for configuring Pupppet before running it.
      class Puppet < Base
        PRIVATE_KEY_BASE_PATH = Pathname("/var/lib/puppet/ssl/private_keys").freeze
        PUBLIC_KEY_BASE_PATH = Pathname("/var/lib/puppet/ssl/public_keys").freeze

        # List of packages to install
        #
        # Only puppet is needed.
        #
        # @return [Hash] Packages to install/remove
        def packages
          { "install" => ["puppet"] }
        end

      private

        # Update Puppet's configuration
        #
        # At this time, only the master server is handled.
        #
        # @see Yast::CM::Configurators::Base#update_configuration
        # @see #master
        def update_configuration
          return unless master.is_a?(::String)
          log.info "Updating puppet configuration file"
          config = CFA::Puppet.new
          config.load
          config.server = master
          config.save
        end

        # Return path to private key
        #
        # @return [Pathname] Path to private key
        def private_key_path
          PRIVATE_KEY_BASE_PATH.join("#{hostname}.pem")
        end

        # Return path to public key
        #
        # @return [Pathname] Path to public_key
        def public_key_path
          PUBLIC_KEY_BASE_PATH.join("#{hostname}.pem")
        end

        # Return FQDN
        #
        # @return [String] FQDN
        def hostname
          return @hostname unless @hostname.nil?
          Yast.import "Hostname"
          @hostname = Yast::Hostname.CurrentFQ()
        end
      end
    end
  end
end
