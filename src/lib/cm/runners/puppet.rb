require "cm/runners/base"
require "cheetah"

module Yast
  module CM
    module Runners
      class Puppet < Base
        include Yast::Logger

        # Try to apply system configuration in client mode
        #
        # @param stdout   [IO]     Standard output channel used by the configurator
        # @param stderr   [IO]     Standard error channel used by the configurator
        # @param _attempt [Fixnum] Attempt number
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_client_mode
        def run_client_mode(stdout, stderr, _attempt)
          Cheetah.run("puppet", "agent", "--onetime",
            "--debug", "--no-daemonize", "--waitforcert", timeout.to_s,
            stdout: stdout, stderr: stderr)
          true
        rescue Cheetah::ExecutionFailed
          false
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
          Cheetah.run("puppet", "apply", "--modulepath",
            config_dir.join("modules").to_s,
            config_dir.join("manifests", "site.pp").to_s, "--debug",
            stdout: stdout, stderr: stderr)
          true
        rescue Cheetah::ExecutionFailed
          false
        end
      end
    end
  end
end
