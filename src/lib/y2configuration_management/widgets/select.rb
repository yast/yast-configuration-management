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

module Y2ConfigurationManagement
  module Widgets
    # This class represents a select widget
    class Select < ::CWM::ComboBox
      # @return [String] Widget label
      attr_reader :label
      # @return [Array<String>] Widget items
      attr_reader :items
      # @return [String,nil] Default value
      attr_reader :default
      # @return [String] Form element locator
      attr_reader :locator
      # @return [String] Form element id
      attr_reader :id

      # Constructor
      #
      # @param spec       [Y2ConfigurationManagement::Salt::FormElement] Element specification
      # @param controller [Y2ConfigurationManagement::Salt::FormController] Form controller
      def initialize(spec, controller)
        @label = spec.label
        @items = spec.values.map { |v| [v, v] }
        @default = spec.default
        @locator = spec.locator
        @id = spec.id
        @controller = controller
        self.widget_id = "select:#{spec.id}"
        # Allow #value= before #init.
        # Wrap the :value accessor to add an "uninitialized" state
        # (which the YUI/CWM widget does not have)
        # so that we can give it a default
        @value = nil
      end

      def value
        @value = super
      end

      def value=(value)
        @value = value
        super
      end

      # @see CWM::AbstractWidget
      def init
        return if default.nil? # combo cannot have no value; prevent YUI error
        self.value = @value || default
      end

    private

      attr_reader :controller
    end
  end
end
