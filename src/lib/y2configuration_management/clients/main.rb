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
require "y2configuration_management/clients/provision"
require "y2configuration_management/configurators/salt"
require "y2configuration_management/configurations/salt"
require "y2configuration_management/salt/formula"

Yast.import "WFM"
Yast.import "PackageSystem"

module Y2ConfigurationManagement
  module Clients
    # Basic client to run the configuration management tools
    #
    # It reads the configuration from an XML file if present (and given as first argument).
    # Otherwise, it uses the default values (based on Salt).
    #
    # @example Configuration example
    #   <configuration_management>
    #     <type>salt</type>
    #     <formulas_sets config:type="list">
    #       <listentry>
    #         <metadata_root>/usr/share/susemanager/formulas/metadata</metadata_root>
    #         <states_root>/usr/share/susemanager/formulas/states</states_root>
    #         <pillar_root>/srv/susemanager/formula_data</pillar_root>
    #       </listentry>
    #       <listentry>
    #         <metadata_root>/srv/formula_metadata</metadata_root>
    #       </listentry>
    #     </formulas_sets>
    #   </configuration_management>
    class Main < Yast::Client
      include Yast::Logger

      # @see https://documentation.suse.com/external-tree/en-us/suma/3.2/susemanager-best-practices/single-html/book.suma.best.practices/book.suma.best.practices.html#best.practice.salt.formulas.what
      SUMA_FORMULAS_BASE = "/usr/share/susemanager/formulas".freeze
      FORMULAS_BASE = "/usr/share/salt-formulas".freeze

      # FIXME: define default values in the {Y2ConfigurationManagement::Configurations} module.
      DEFAULT_SETTINGS = {
        "type"          => "salt",
        "formulas_sets" => [
          {
            "metadata_root" => File.join(SUMA_FORMULAS_BASE, "metadata"),
            "states_root"   => File.join(SUMA_FORMULAS_BASE, "states"),
            "pillar_root"   => "/srv/susemanager/formula_data/pillar"
          },
          {
            "metadata_root" => File.join(FORMULAS_BASE, "metadata"),
            "states_root"   => File.join(FORMULAS_BASE, "states"),
            "pillar_root"   => "/srv/salt-formulas/pillar"
          },
          {
            "metadata_root" => "/srv/formula_metadata"
          }
        ],
        "states_roots"  => [
          "/srv/salt"
        ]
      }.freeze

      # Runs the client
      def run
        settings = settings_from_xml || DEFAULT_SETTINGS
        log.info("Provisioning Configuration Management")
        config = Y2ConfigurationManagement::Configurations::Base.import(settings)
        configurator = Y2ConfigurationManagement::Configurators::Base.for(config)
        ret = configurator.prepare(require_formulas: true)
        return ret unless ret == :finish
        if !Yast::PackageSystem.CheckAndInstallPackages(configurator.packages.fetch("install", []))
          return :abort
        end
        Y2ConfigurationManagement::Clients::Provision.new.run
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
