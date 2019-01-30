# encoding: utf-8
#
# Copyright (c) [2019] SUSE LLC
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

require "y2configuration_management/widgets/text"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a color text field
    class Color < Text
      VALID_COLOR_REGEXP = /\A#(\h{3}){1,2}\z/
      # Constructor
      #
      # @param spec         [Salt::FormInput] Input specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, data_locator)
        textdomain "configuration_management"
        super
        self.widget_id = "color:#{spec.id}"
      end

      def validate
        return true if value.to_s.empty? || value =~ VALID_COLOR_REGEXP
        # TRANSLATORS: It reports that %s is an invalid HEX color.
        Yast::Report.Error(_("%s: is not a valid") % label)

        false
      end
    end
  end
end
