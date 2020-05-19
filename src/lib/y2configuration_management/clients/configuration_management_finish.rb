require "yast"
require "installation/finish_client"
require "y2configuration_management/configurators/base"
require "y2configuration_management/configurations/base"
require "y2configuration_management/clients/provision"

Yast.import "Service"

module Y2ConfigurationManagement
  # Client to write the provisioner's configuration
  #
  # This client requires that the configurator and the configurators are already
  # available (see {AutoClient}).
  #
  # @see Configurators
  # @see Configurations
  # @see Provision
  class ConfigurationManagementFinish < ::Installation::FinishClient
    include Yast::I18n

    def initialize
      textdomain "configuration_management"
    end

    # Writes configuration
    #
    #
    # @return [TrueClass,FalseClass] True if configurations have been written;
    #                                otherwise it returns false.
    def write
      return false if config.nil?
      log.info("Provisioning Configuration Management with config #{config.inspect}")
      configurator.prepare(require_formulas: false)
      # saving settings to target system
      Y2ConfigurationManagement::Clients::Provision.new.run

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
      @configurator ||= Y2ConfigurationManagement::Configurators::Base.current
    end

    def config
      @config ||= Y2ConfigurationManagement::Configurations::Base.current
    end
  end
end
