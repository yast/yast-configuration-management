require "yast"
require "cm/runners/base"
require "cm/dialogs/running"
require "cm/configurations/base"

module Yast
  module CM
    module Clients
      # This client takes care of running the provisioning in order to configure the system.
      # The real work is implemented by runners.
      #
      # @see Yast::CM::Runners
      class Provision < Client
        # Run the client
        def run
          return false unless runner
          dialog = Yast::CM::Dialogs::Running.new
          dialog.run do |stdout, stderr|
            # Connect stdout and stderr with the dialog
            runner.run(stdout, stderr)
          end
          true
        end

      private

        # Returns the runner to use
        #
        # @return [Yast::CM::Runners::Base] Runner
        def runner
          return @runner if @runner
          @runner = Yast::CM::Runners::Base.runner_for(config) if config
        end

        # Returns the module configuration
        #
        # @return [Yast::CM::Config] Module configuration
        def config
          @config ||= Yast::CM::Configurations::Base.load
        end
      end
    end
  end
end
