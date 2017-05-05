require "configuration_management/runners/base"

module Yast
  module ConfigurationManagement
    module Runners
      # Runs Puppet in order to configure the system
      class Puppet < Base
        # Try to apply system configuration in client mode
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::ConfigurationManagement::Runners::Base#run_client_mode
        def run_client_mode(stdout, stderr)
          with_retries(config.auth_attempts) do
            run_cmd("puppet", "agent", "--onetime",
              "--debug", "--no-daemonize", "--waitforcert", config.auth_time_out.to_s,
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
        # @see Yast::ConfigurationManagement::Runners::Base#run_masterless_mode
        def run_masterless_mode(stdout, stderr)
          with_retries(config.auth_attempts) do
            run_cmd("puppet", "apply", "--modulepath",
              config.work_dir(:target).join("modules").to_s,
              config.work_dir(:target).join("manifests", "site.pp").to_s, "--debug",
              stdout: stdout, stderr: stderr)
          end
        end
      end
    end
  end
end
