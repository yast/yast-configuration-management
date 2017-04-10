require "yast"
require "installation/finish_client"
require "configuration_management/configurators/base"
require "configuration_management/configurations/base"
require "configuration_management/clients/provision"

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
        log.info("Provisioning Configuration Management")
        config = Yast::ConfigurationManagement::Configurations::Base.load
        return true unless config # No configuration has been done
        configurator = Yast::ConfigurationManagement::Configurators::Base.for(config)
        configurator.prepare if configurator
        # saving settings to target system
        config.secure_save
        Yast::ConfigurationManagement::Clients::Provision.new.run
        true
      end

      def modes
        [:autoinst, :autoupg]
      end

      def title
        _("Provisioning Configuration Management ...")
      end
    end
  end
end
