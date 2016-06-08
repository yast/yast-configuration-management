require "yast"
require "yast2/execute"
require "scm/cfa/puppet"

module Yast
  module SCM
    # Puppet integration handler
    class PuppetProvisioner < Provisioner
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
      # @see Yast::SCM::Provisioner#update_configuration
      # @see #master
      def update_configuration
        return unless master.is_a?(::String)
        log.info "Updating puppet configuration file"
        config = CFA::Puppet.new
        config.load
        config.server = master
        config.save
      end

      # Try to apply system configuration
      #
      # @see Yast::SCM::Provisioner#try_to_apply
      def try_to_apply
        Yast::Execute.locally("puppet", "agent", "--onetime",
          "--no-daemonize", "--waitforcert", auth_timeout.to_s)
        true
      rescue
        false
      end
    end
  end
end
