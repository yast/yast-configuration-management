require "yast"
require "y2configuration_management/runners/base"
require "y2configuration_management/dialogs/running"
require "y2configuration_management/configurations/base"

module Y2ConfigurationManagement
  module Clients
    # TODO: move this code to the finish client

    # This client takes care of running the provisioning in order to configure the system.
    # The real work is implemented by runners.
    #
    # @see Y2ConfigurationManagement::Runners
    class Provision < Yast::Client
      # Run the client
      def run
        return false unless runner
        dialog = Y2ConfigurationManagement::Dialogs::Running.new
        dialog.run do |stdout, stderr|
          # Connect stdout and stderr with the dialog
          runner.run(stdout, stderr)
        end
        true
      end

    private

      # Returns the runner to use
      #
      # @return [Y2ConfigurationManagement::Runners::Base] Runner
      def runner
        return @runner if @runner
        @runner = Y2ConfigurationManagement::Runners::Base.for(config) if config
      end

      # Returns the module configuration
      #
      # @return [Y2ConfigurationManagement::Config] Module configuration
      def config
        @config ||= Y2ConfigurationManagement::Configurations::Base.current
      end
    end
  end
end
