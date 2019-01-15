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
  # This module contains the widgets which are used to display forms for Salt formulas
  module Widgets
    # This class represents a boolean (checkbox) field. TODO: is tristate possible?
    class Boolean < ::CWM::ReplacePoint
      # @return [String] Widget label
      attr_reader :label
      # @return [Boolean] Default value
      attr_reader :default
      # @return [String] Form locator
      attr_reader :locator
      # @return [String] Form element id
      attr_reader :id

      # Constructor
      #
      # @param spec [Y2ConfigurationManagement::Salt::FormElement] Element specification
      # @param controller [FormController] Form controller
      def initialize(spec, controller)
        @label = spec.label
        @default = spec.default == true # nil -> false
        @controller = controller
        @locator = spec.locator
        @id = spec.id
        
        @inner = CWM::CheckBox.new
        @inner.widget_id = "boolean:#{spec.id}"
        super(id: "vis:#{spec.id}", widget: @inner)
        @visible = true
        # ^: manual visibility
        # v: automatic
        @visible_if = spec.visible_if 
      end

      # @see CWM::AbstractWidget
      def init
        self.value = default
      end

      attr_reader :visible

      def visible=(visible)
        return if @visible == visible
        @visible = visible
        if visible
          replace(@inner)
        else
          replace(Empty())
        end
      end

      # Automatic invisibility: when the form controller asks us,
      # we evaluate a condition and update our visibility
      def update_visibility
        # Hmm, the evaluation does not really depend on self, but on ANOTHER widget
        # that should be passed?/found?
        self.visible = @visible_if.evaluate(self)
      end
    end
  end
end
