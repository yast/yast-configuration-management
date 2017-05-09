require "yast"
require "cheetah"
require "configuration_management/cfa/puppet"
require "configuration_management/configurators/base"
require "pathname"

Yast.import "Pkg"

module Yast
  module ConfigurationManagement
    module Configurators
      # Puppet configurator
      #
      # This class is responsible for configuring Pupppet before running it.
      class Puppet < Base
        include Yast::Logger

        PRIVATE_KEY_BASE_PATH = Pathname("/var/lib/puppet/ssl/private_keys").freeze
        PUBLIC_KEY_BASE_PATH = Pathname("/var/lib/puppet/ssl/public_keys").freeze

        mode(:masterless) do
          update_configuration
          fetch_config(config.modules_url, config.work_dir)
        end

        mode(:client) do
          update_configuration
          fetch_keys(config.keys_url, private_key_path, public_key_path)
        end

        # List of packages to install
        #
        # Only puppet is needed.
        #
        # @return [Hash] Packages to install/remove
        def packages
          candidates = Yast::Pkg.PkgQueryProvides("puppet")
          if candidates.empty?
            log.warn "A package providing 'puppet' was not found"
            return {}
          end
          { "install" => Array(candidates[0][0]) }
        end

      private

        # Update Puppet's configuration
        #
        # At this time, only the master server is handled.
        #
        # @see Yast::ConfigurationManagement::Configurators::Base#update_configuration
        # @see #master
        def update_configuration
          return unless config.master.is_a?(::String)
          log.info "Updating puppet configuration file"
          config_file = CFA::Puppet.new
          config_file.load
          config_file.server = config.master
          config_file.save
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
