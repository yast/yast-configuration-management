require "yast"
require "yast2/execute"
require "scm/cfa/minion"

module Yast
  module SCM
    class SaltProvisioner
      include Yast::Logger

      # @return [String] Master server hostname
      attr_reader :master
      # @return [Integer] Number of authentication retries
      attr_reader :auth_retries
      # @return [Integer] Authentication timeout for each retry
      attr_reader :auth_timeout

      # Constructor
      #
      # @param config [Hash] options
      # @option config [String] Master server hostname
      def initialize(config = {})
        log.info "Initializing SaltProvisioner with #{config}"
        @master = config["master"]
        @auth_retries = config["auth_retries"] || 3
        @auth_timeout = config["auth_timeout"] || 10
      end

      # List of packages to install
      #
      # Only salt-minion is needed.
      #
      # @return [Hash] Packages to install/remove
      def packages
        { "install" => ["salt-minion"] }
      end

      # Apply the configuration
      #
      # @see update_config_file
      # @see apply
      def run
        update_config_file
        apply
      end

    private

      # Update the minion's configuration file
      #
      # At this time, only the master server is handled
      # according to #master.
      #
      # @see #master
      def update_config_file
        return unless master.is_a?(::String)
        log.info "Updating minion configuration file"
        minion_config = CFA::Minion.new
        minion_config.load
        minion_config.master = master
        minion_config.save
      end

      # Apply configuration
      def apply
        tries = 1
        begin
          log.info "Applying configuratio (try #{tries}/#{auth_retries})"
          Yast::Execute.locally("salt-call", "state.highstate")
        rescue
          return false if tries == auth_retries
          tries += 1
          sleep auth_timeout
          retry
        end
        true
      end
    end
  end
end
