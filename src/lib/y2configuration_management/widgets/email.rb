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
    # This class represents an email text field
    class Email < Text
      # Constructor
      #
      # @param spec [Y2ConfigurationManagement::Salt::FormInput] Element specification
      def initialize(spec)
        textdomain "configuration_management"
        super
        self.widget_id = "email:#{spec.id}"
      end

      def validate
        return true if value.to_s.empty?

        Yast.import "Report"
        unless value.match(URI::MailTo::EMAIL_REGEXP)
          # TRANSLATORS: It reports that %s is an invalid email.
          Yast::Report.Error(_("%s: is not valid") % label)
          return false
        end

        true
      end
    end
  end
end
