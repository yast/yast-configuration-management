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

require "cwm"
require "y2configuration_management/widgets/base_mixin"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a simple date field
    class Date < ::CWM::DateField
      include BaseMixin

      attr_reader :default

      # Constructor
      #
      # @param spec         [Salt::FormInput] Input specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, data_locator)
        initialize_base(spec, data_locator)
        @default = spec.default
        self.widget_id = "date:#{spec.id}"
        @value = nil
      end

      # @see CWM::ValueBasedWidget
      def value=(val)
        @value = val
        super
      end

      # @see CWM::AbstractWidget
      def init
        return if default.to_s.empty? # date cannot have no value; prevent YUI error
        self.value = @value || default
      end
    end
  end
end
