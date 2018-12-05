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
    # Represents a group of elements
    class Group < ::CWM::CustomWidget
      # @return [String] Widget label
      attr_reader :label
      # @return [String] Form element path
      attr_reader :path
      # @return [Array<CWM::AbstractWidget>] Widgets which are included in the group
      attr_reader :children
      attr_reader :id

      # Constructor
      #
      # @param spec       [Y2ConfigurationManagement::Salt::FormElement] Element specification
      # @param children   [Array<AbstractWidget>] Widgets which are included in the group
      # @param controller [Y2ConfigurationManagement::Salt::FormController] Form controller
      def initialize(spec, children, controller)
        textdomain "configuration_management"
        @label = spec.label
        @children = children
        @controller = controller
        @path = spec.path
        @id = spec.id
        self.widget_id = "group:#{spec.id}"
      end

      # Widget contents
      #
      # @return [Yast::Term]
      def contents
        VBox(*children)
      end

      # Sets the value for the form
      #
      # This method propagates the values to the underlying widgets.
      #
      # @example Setting values for included widgets
      #   form.values = { "name" => "John", "surname" => "Doe" }
      # @example Setting values for nested widgets
      #   form.values = { "ranges" => [ { "start" => "10.0.0.10", "end" => "10.0.0.20" } ] }
      #
      # @param values [Hash] New value
      def value=(values)
        children.each do |widget|
          widget.value = values[widget.id]
        end
      end

      # Returns form widgets
      #
      # This method gets the values from the underlying widgets returning them in a
      # hash index by widget ids.
      #
      # @return [Hash]
      # @see #value=
      def value
        children.reduce({}) { |a, e| a.merge(e.id => e.value) }
      end
    end
  end
end
