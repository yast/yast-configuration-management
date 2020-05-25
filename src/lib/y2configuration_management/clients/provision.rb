require "yast"
require "y2configuration_management/runners/base"
require "y2configuration_management/dialogs/running"
require "y2configuration_management/configurations/base"

Yast.import "Report"

module Y2ConfigurationManagement
  module Clients
    # This client takes care of provisioning the system, although the real work
    # is implemented by its correspondant {Runners}.
    #
    # It is used by {ConfigurationManagementFinish}, {Main} and firstboot clients.
    #
    # @see Y2ConfigurationManagement::Runners
    # TODO: use a regular class instead of a client.
    class Provision < Yast::Client
      # Run the client
      def run
        return false unless runner
        dialog = Y2ConfigurationManagement::Dialogs::Running.new(reporting_opts: reporting_opts)
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

      DEFAULT_REPORTING_OPTS = {
        open_after_success: true, open_after_error: true
      }.freeze
      private_constant :DEFAULT_REPORTING_OPTS

      # Determines the reporting options
      #
      # During autoinstallation, the options depend on the AutoYaST reporting settings.
      #
      # @return [Hash]
      def reporting_opts
        return DEFAULT_REPORTING_OPTS unless Yast::Mode.auto
        messages = Yast::Report.message_settings
        errors = Yast::Report.error_settings
        opts = {
          open_after_success: messages["show"],
          open_after_error:   errors["show"]
        }
        opts[:timeout_after_success] = messages["timeout"] if opts[:open_after_success]
        opts[:timeout_after_error] = errors["timeout"] if opts[:open_after_error]
        opts
      end
    end
  end
end
