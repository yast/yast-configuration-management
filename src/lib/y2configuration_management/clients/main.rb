# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "configuration_management/clients/provision"
require "configuration_management/configurators/salt"
require "configuration_management/configurations/salt"
Yast.import "WFM"
Yast.import "PackageSystem"

module Y2ConfigurationManagement
  module Clients
    # Basic client to run the configuration management tools
    #
    # It reads the configuration from an XML file.
    #
    # @example Configuration example
    #   <configuration_management>
    #     <type>salt</type>
    #     <states_roots config:type="list">
    #       <listitem>/srv/salt</listitem>
    #     </states_roots>
    #     <formulas_roots config:type="list">
    #       <listitem>/srv/formulas</listitem>
    #     </formulas_roots>
    #     <pillar_root>/srv/pillar</pillar_root>
    #   </configuration_management>
    class Main < Yast::Client
      include Yast::Logger

      # Runs the client
      def run
        settings = settings_from_xml
        return false unless settings
        log.info("Provisioning Configuration Management")
        config = Yast::ConfigurationManagement::Configurations::Base.import(settings)
        configurator = Yast::ConfigurationManagement::Configurators::Base.for(config)
        if !Yast::PackageSystem.CheckAndInstallPackages(configurator.packages.fetch("install", []))
          return :abort
        end
        configurator.prepare
        Yast::ConfigurationManagement::Clients::Provision.new.run
      end

    private

      # Reads the module settings from an XML file
      #
      # @return [Hash,nil]
      def settings_from_xml
        filename = Yast::WFM.Args(0)
        return nil unless filename && File.exist?(filename)
        content = Yast::XML.XMLToYCPFile(filename)
        content && content["configuration_management"]
      end
    end
  end
end
