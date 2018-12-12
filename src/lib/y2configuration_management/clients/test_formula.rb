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

require "y2configuration_management/salt/formula"
require "y2configuration_management/salt/form_controller"

module Y2ConfigurationManagement
  module Clients
    # Sample client to try the new Salt formulas implementation
    class TestFormula
      include Yast::I18n
      include Yast::UIShortcuts

      def run
        textdomain "configuration_management"

        formula = Salt::Formula.new(Pathname.new("test/fixtures"), pillar)
        pillar = Salt::Pillar.from_file("test/fixtures/pillar/test-formula.sls")
        controller = Salt::FormController.new(formula.form, pillar)
        controller.show_main_dialog
      end
    end
  end
end
