require "yast"
require "cheetah"
require "cm/cfa/puppet"
require "cm/provisioner"
require "pathname"

module Yast
  module CM
    # Puppet integration handler
    class PuppetProvisioner < Provisioner
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

      # Update puppet's configuration
      #
      # At this time, only the master server is handled.
      #
      # @see Yast::CM::Provisioner#update_configuration
      # @see #master
      def update_configuration
        return unless master.is_a?(::String)
        log.info "Updating puppet configuration file"
        config = CFA::Puppet.new
        config.load
        config.server = master
        config.save
      end

      # Try to apply system configuration in client mode
      #
      # @param stdout [IO] Standard output channel used by the provisioner
      # @param stderr [IO] Standard error channel used by the provisioner
      #
      # @return [Boolean] +true+ if run was successful; +false+ otherwise.
      #
      # @see Yast::CM::Provisioner#apply_client_mode
      def apply_client_mode(stdout, stderr)
        Cheetah.run("puppet", "agent", "--onetime",
          "--debug", "--no-daemonize", "--waitforcert", timeout.to_s,
          stdout: stdout, stderr: stderr)
        true
      rescue Cheetah::ExecutionFailed
        false
      end

      # Try to apply system configuration in masterless mode
      #
      # @param stdout [IO] Standard output channel used by the provisioner
      # @param stderr [IO] Standard error channel used by the provisioner
      #
      # @return [Boolean] +true+ if run was successful; +false+ otherwise.
      #
      # @see Yast::CM::Provisioner#apply_masterless_mode
      def apply_masterless_mode(stdout, stderr)
        Cheetah.run("puppet", "apply", "--modulepath",
          config_tmpdir.join("modules").to_s,
          config_tmpdir.join("manifests", "site.pp").to_s, "--debug",
          stdout: stdout, stderr: stderr)
        true
      rescue Cheetah::ExecutionFailed
        false
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
