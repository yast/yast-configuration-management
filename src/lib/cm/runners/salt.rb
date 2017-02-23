require "cm/runners/base"
require "cheetah"

module Yast
  module CM
    module Runners
      # Runs Salt in order to configure the system
      class Salt < Base

      private

        # Try to apply system configuration in client mode
        #
        # The Salt runner does not care about retries and auth_time_outs as they
        # are set in the minion's configuration file.
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_client_mode
        def run_client_mode(stdout, stderr)
          with_retries(config.auth_attempts, config.auth_time_out) do
            run_cmd("salt-call", "--log-level", "debug", "state.highstate",
              stdout: stdout, stderr: stderr)
          end
        end

        # Try to apply system configuration in masterless mode
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_masterless_mode
        def run_masterless_mode(stdout, stderr)
          with_retries(config.auth_attempts, config.auth_time_out) do
            run_cmd("salt-call", "--log-level", "debug", "--local",
              *masterless_options, "state.highstate",
              stdout: stdout, stderr: stderr)
          end
        end

      private

        # Map command line options to config values
        MASTERLESS_OPTIONS_MAP = {
          "pillar-root" => :pillar_root,
          "file-root"   => :states_root
        }.freeze

        # Returns an array of options to use in masterless mode
        #
        # Options are always sorted alphabetically.
        #
        # @return [Array<String>] Array of options
        def masterless_options
          MASTERLESS_OPTIONS_MAP.sort_by { |n, m| n  }.each_with_object([]) do |option, all|
            name, meth = option
            value = config.send(meth)
            all.push("--#{name}=#{value}") if value
          end
        end
      end
    end
  end
end
