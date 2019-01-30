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
require "uri"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a URL text field
    class URL < Text
      # Constructor
      #
      # @param spec         [Salt::FormInput] Element specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, data_locator)
        textdomain "configuration_management"
        super
        self.widget_id = "url:#{spec.id}"
      end

      def validate
        return true if value.to_s.empty?

        Yast.import "URL"
        begin
          return true if URI.parse(value)
        rescue
          # TRANSLATORS: It reports that %s is an invalid URL.
          Yast::Report.Error(_("%s: is not valid") % label)
        end

        false
      end
    end
  end
end
