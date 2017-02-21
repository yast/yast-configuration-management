require "cm/runners/base"
require "cheetah"

module Yast
  module CM
    module Runners
      class Puppet < Base
        include Yast::Logger

        # Try to apply system configuration in client mode
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_client_mode
        def run_client_mode(stdout, stderr)
          with_retries(auth_attempts) do
            run_cmd("puppet", "agent", "--onetime",
              "--debug", "--no-daemonize", "--waitforcert", auth_time_out.to_s,
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
          with_retries(auth_attempts) do
            run_cmd("puppet", "apply", "--modulepath",
              definitions_root.join("modules").to_s,
              definitions_root.join("manifests", "site.pp").to_s, "--debug",
              stdout: stdout, stderr: stderr)
          end
        end
      end
    end
  end
end
