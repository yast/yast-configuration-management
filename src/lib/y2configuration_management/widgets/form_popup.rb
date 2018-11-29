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

require "cwm/popup"

module Y2ConfigurationManagement
  module Widgets
    # This dialog displays a set of widgets in a popup
    class FormPopup < ::CWM::Popup
      # @return [String] Popup title
      attr_reader :title

      # Constructor
      #
      # @param title [String] Popup title
      # @param contents [Array<CWM::AbstractWidget>] Popup content (as an array of CWM widgets)
      def initialize(title, content)
        @inner_content = content
        @title = title
      end

      # Widget's content
      #
      # @see CWM::AbstractWidget#contents
      def contents
        VBox(*@inner_content)
      end
    end
  end
end
