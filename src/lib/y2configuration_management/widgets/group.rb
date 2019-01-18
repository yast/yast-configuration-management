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
      include BaseMixin

      # @return [Array<CWM::AbstractWidget>] Widgets which are included in the group
      attr_reader :children

      # Constructor
      #
      # @param spec       [Y2ConfigurationManagement::Salt::FormElement] Element specification
      # @param children   [Array<AbstractWidget>] Widgets which are included in the group
      def initialize(spec, children)
        textdomain "configuration_management"
        initialize_base(spec)
        self.widget_id = "group:#{spec.id}"
        add_children(*children)
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
      #   form.value = { "name" => "John", "surname" => "Doe" }
      # @example Setting values for nested widgets
      #   form.value = { "ranges" => [ { "start" => "10.0.0.10", "end" => "10.0.0.20" } ] }
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

      # Add children widgets
      #
      # @param widgets [Array<CWM::AbstractWidget>] Widgets to add to the group
      def add_children(*widgets)
        @children ||= []
        widgets.each { |w| w.parent = self }
        @children.concat(widgets)
      end
    end
  end
end
