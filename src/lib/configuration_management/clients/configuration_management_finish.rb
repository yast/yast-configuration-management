require "yast"
require "installation/finish_client"
require "configuration_management/configurators/base"
require "configuration_management/configurations/base"
require "configuration_management/clients/provision"

Yast.import "Service"

module Yast
  module ConfigurationManagement
    # Client to write the provisioner's configuration
    #
    # @see Yast::ConfigurationManagement::Configurators
    class ConfigurationManagementFinish < ::Installation::FinishClient
      include Yast::I18n

      def initialize
        textdomain "installation"
      end

      # Writes configuration
      #
      #
      # @return [TrueClass,FalseClass] True if configurations have been written;
      #                                otherwise it returns false.
      def write
        return false if config.nil?
        log.info("Provisioning Configuration Management")
        configurator.prepare
        # saving settings to target system
        Yast::ConfigurationManagement::Clients::Provision.new.run

        # enabling services
        if config.enable_services
          configurator.services.each { |s| Service.Enable(s) }
        end

        true
      end

      def modes
        [:autoinst, :autoupg]
      end

      def title
        _("Provisioning Configuration Management ...")
      end

    private

      def configurator
        @configurator ||= Yast::ConfigurationManagement::Configurators::Base.current
      end

      def config
        @config ||= Yast::ConfigurationManagement::Configurations::Base.current
      end
    end
  end
end
