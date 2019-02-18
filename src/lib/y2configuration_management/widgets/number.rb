# encoding: utf-8

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
require "y2configuration_management/widgets/visibility_switcher"
require "y2configuration_management/widgets/salt_visibility_switcher"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a number field
    class Number < VisibilitySwitcher
      include BaseMixin

      include SaltVisibilitySwitcher

      # A helper to go inside a ReplacePoint
      class NumberField < ::CWM::InputField
        attr_reader :label

        def initialize(id:, label:)
          self.widget_id = id
          @label = label
        end

        # TODO: only if I am mentioned in a visible_if
        def opt
          [:notify]
        end

        def value
          ret = super
          return nil if ret.nil? || ret.empty?
          ret.to_i
        end
      end

      # Constructor
      #
      # @param spec    [Y2ConfigurationManagement::Salt::FormInput] Input specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, data_locator)
        initialize_base(spec, data_locator)

        inner = NumberField.new(id: "number:#{spec.id}", label: spec.label)
        super(id: "vis:#{spec.id}", widget: inner)
        initialize_salt_visibility_switcher(spec.visible_if)
      end

      # @see CWM::AbstractWidget
      def init
        saved_value = value
        replace(inner)
        self.value = saved_value.to_s
      end

      # @see CWM::ValueBasedWidget
      def value=(val)
        super(val.to_s)
      end
    end
  end
end
