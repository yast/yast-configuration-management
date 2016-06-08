require "yast"
require "yast2/execute"
require "scm/cfa/minion"
require "scm/provisioner"

module Yast
  module SCM
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
      # At this time, only the master server is handled
      # according to #master.
      #
      # @see #master
      def update_configuration
        return unless master.is_a?(::String)
        log.info "Updating minion configuration file"
        config = CFA::Minion.new
        config.load
        config.master = master
        config.save
      end

      # Apply configuration
      def try_to_apply
        Yast::Execute.locally("salt-call", "state.highstate")
        true
      rescue
        sleep auth_timeout
        false
      end
    end
  end
end
