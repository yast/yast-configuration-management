require "yast"
require "yast2/execute"
require "scm/cfa/minion"
require "scm/provisioner"

module Yast
  module SCM
    # Salt integration handler
    class SaltProvisioner < Provisioner
      # List of packages to install
      #
      # Only salt-minion is needed.
      #
      # @return [Hash] Packages to install/remove
      def packages
        { "install" => ["salt-minion"] }
      end

    private

      # Update the minion's configuration file
      #
      # At this time, only the master server is handled.
      #
      # @see Yast::SCM::Provisioner#update_configuration
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
      # @see Yast::SCM::Provisioner#apply_client_mode
      def apply_client_mode
        Yast::Execute.locally("salt-call", "state.highstate")
        true
      rescue
        sleep timeout
        false
      end

      # Try to apply system configuration in masterless mode
      #
      # @see Yast::SCM::Provisioner#apply_masterless_mode
      def apply_masterless_mode
        Yast::Execute.locally("salt-call", "--local",
          "--file-root=#{config_tmpdir}", "state.highstate")
        true
      rescue
        false
      end

    end
  end
end
