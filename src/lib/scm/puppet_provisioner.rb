require "yast"
require "yast2/execute"
require "scm/cfa/puppet"

module Yast
  module SCM
    class PuppetProvisioner < Provisioner
      include Yast::Logger

      # List of packages to install
      #
      # Only puppet is needed.
      #
      # @return [Hash] Packages to install/remove
      def packages
        { "install" => ["puppet"] }
      end

    private

      # Update the puppet's configuration file
      #
      # At this time, only the master server is handled
      # according to #master.
      #
      # @see #master
      def update_configuration
        return unless master.is_a?(::String)
        log.info "Updating puppet configuration file"
        config = CFA::Puppet.new
        config.load
        config.server = master
        config.save
      end

      # Apply configuration
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
