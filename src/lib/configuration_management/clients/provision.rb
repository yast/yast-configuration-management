require "yast"
require "configuration_management/runners/base"
require "configuration_management/dialogs/running"
require "configuration_management/configurations/base"

module Yast
  module ConfigurationManagement
    module Clients
      # TODO: move this code to the finish client

      # This client takes care of running the provisioning in order to configure the system.
      # The real work is implemented by runners.
      #
      # @see Yast::ConfigurationManagement::Runners
      class Provision < Client
        # Run the client
        def run
          return false unless runner
          dialog = Yast::ConfigurationManagement::Dialogs::Running.new
          dialog.run do |stdout, stderr|
            # Connect stdout and stderr with the dialog
            runner.run(stdout, stderr)
          end
          true
        end

      private

        # Returns the runner to use
        #
        # @return [Yast::ConfigurationManagement::Runners::Base] Runner
        def runner
          return @runner if @runner
          @runner = Yast::ConfigurationManagement::Runners::Base.for(config) if config
        end

        # Returns the module configuration
        #
        # @return [Yast::ConfigurationManagement::Config] Module configuration
        def config
          @config ||= Yast::ConfigurationManagement::Configurations::Base.current
        end
      end
    end
  end
end
