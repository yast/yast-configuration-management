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
require "y2configuration_management/salt/formula"

module Y2ConfigurationManagement
  module Clients
    # Client to configure formulas
    class Main < Yast::Client
      include Yast::Logger

      def run
        log.info("Provisioning Configuration Management")
        configurator = Yast::ConfigurationManagement::Configurators::Base.for(config)
        configurator.prepare
        Yast::ConfigurationManagement::Clients::Provision.new.run
      end

    private

      # Returns the configuration management configuration
      #
      # @return [Yast::ConfigurationManagement::Configurations::Base]
      def config
        return @config if @config
        settings =
          {
            "type"           => "salt",
            "mode"           => "masterless",
            "formulas_roots" => Y2ConfigurationManagement::Salt::Formula.formula_directories,
            "states_roots"   => Y2ConfigurationManagement::Salt::Formula::BASE_DIR + "/states",
            "pillar_root"    => Y2ConfigurationManagement::Salt::Formula::DATA_DIR + "/pillar"
          }
        @config = Yast::ConfigurationManagement::Configurations::Base.import(settings)
      end
    end
  end
end
