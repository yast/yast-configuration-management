require "cm/runners/base"
require "cheetah"

module Yast
  module CM
    module Runners
      class Salt < Base
        include Yast::Logger

      private

        # Try to apply system configuration in client mode
        #
        # @param stdout  [IO]     Standard output channel used by the configurator
        # @param stderr  [IO]     Standard error channel used by the configurator
        # @param attempt [Fixnum] Attempt number
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_client_mode
        def run_client_mode(stdout, stderr, attempt)
          Cheetah.run("salt-call", "--log-level", "debug", "state.highstate",
            stdout: stdout, stderr: stderr)
          true
        rescue Cheetah::ExecutionFailed
          sleep timeout if attempt < attempts
          false
        end

        # Try to apply system configuration in masterless mode
        #
        # @param stdout  [IO]     Standard output channel used by the configurator
        # @param stderr  [IO]     Standard error channel used by the configurator
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_masterless_mode
        def run_masterless_mode(stdout, stderr)
          Cheetah.run("salt-call", "--log-level", "debug", "--local",
            "--file-root=#{config_dir}", "state.highstate",
            stdout: stdout, stderr: stderr)
          true
        rescue Cheetah::ExecutionFailed
          sleep timeout if attempt < attempts
          false
        end
      end
    end
  end
end
