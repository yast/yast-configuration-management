require "yast"
require "cheetah"
require "cm/cfa/minion"
require "cm/provisioner"
require "pathname"

module Yast
  module CM
    # Salt integration handler
    class SaltProvisioner < Provisioner
      PRIVATE_KEY_PATH = Pathname("/etc/salt/pki/minion/minion.pem").freeze
      PUBLIC_KEY_PATH = Pathname("/etc/salt/pki/minion/minion.pub").freeze

      # List of packages to install
      #
      # * `salt` includes the `salt-call` command.
      # * `salt-minion` is only needed in client mode
      #
      # @return [Hash] Packages to install/remove
      def packages
        salt_packages = ["salt"]
        salt_packages << "salt-minion" if mode == :client
        { "install" => salt_packages }
      end

    private

      # Update the minion's configuration file
      #
      # At this time, only the master server is handled.
      #
      # @see Yast::CM::Provisioner#update_configuration
      # @see #master
      def update_configuration
        return unless master.is_a?(::String)
        log.info "Updating minion configuration file"
        config = CFA::Minion.new
        config.load
        config.master = master
        config.save
      end

      # Try to apply system configuration
      #
      # @param stdout [IO] Standard output channel used by the provisioner
      # @param stderr [IO] Standard error channel used by the provisioner
      #
      # @return [Boolean] +true+ if run was successful; +false+ otherwise.
      #
      # @see Yast::CM::Provisioner#apply_client_mode
      def apply_client_mode(stdout, stderr)
        Cheetah.run("salt-call", "--log-level", "debug", "state.highstate",
          stdout: stdout, stderr: stderr)
        true
      rescue Cheetah::ExecutionFailed
        sleep timeout
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
        Cheetah.run("salt-call", "--log-level", "debug", "--local",
          "--file-root=#{config_tmpdir}", "state.highstate",
          stdout: stdout, stderr: stderr)
        true
      rescue Cheetah::ExecutionFailed
        false
      end

      # Return path to private key
      #
      # @return [Pathname] Path to private key
      def private_key_path
        PRIVATE_KEY_PATH
      end

      # Return path to public key
      #
      # @return [Pathname] Path to public_key
      def public_key_path
        PUBLIC_KEY_PATH
      end
    end
  end
end
