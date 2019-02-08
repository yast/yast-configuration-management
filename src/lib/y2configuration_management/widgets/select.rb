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

require "cwm"
require "y2configuration_management/widgets/base_mixin"
require "y2configuration_management/widgets/visibility_switcher"
require "y2configuration_management/widgets/salt_visibility_switcher"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a select widget
    class Select < VisibilitySwitcher
      include BaseMixin
      include SaltVisibilitySwitcher

      # Constructor
      #
      # @param spec         [Salt::FormElement] Element specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, data_locator)
        initialize_base(spec, data_locator)

        items = spec.values.map { |v| [v, v.to_s] }
        inner = AlwaysVisibleSelect.new(id:    "select:#{spec.id}",
                                        label: spec.label,
                                        items: items)
        super(id: "vis:#{spec.id}", widget: inner)
        initialize_salt_visibility_switcher(spec.visible_if)
      end

      def items
        inner.items
      end
    end

    # An always visible select widget
    class AlwaysVisibleSelect < ::CWM::ComboBox
      # @return [String] Widget label
      attr_reader :label
      # @return [Array<String>] Widget items
      attr_reader :items

      def initialize(id:, label:, items:)
        self.widget_id = id
        @label = label
        @items = items
      end

      # TODO: only if I am mentioned in a visible_if
      def opt
        [:notify]
      end
    end
  end
end
