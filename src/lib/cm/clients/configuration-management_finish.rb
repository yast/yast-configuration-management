require "yast"
require "installation/finish_client"
require "cm/configurators/base"
require "cm/configurations/base"

module Yast
  module CM
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
        log.info("Provisioning Configuration Management (salt/puppet)")
        config = Yast::CM::Configurations::Base.load
        configurator = Yast::CM::Configurators::Base.for(config)
        configurator.prepare if configurator
        # saving settings to target system
        config.secure_save

        true
      end

      def modes
        [:autoinst, :autoupg]
      end

      def title
        _("Provisioning Configuration Management (salt/puppet)...")
      end

    end
  end
end
