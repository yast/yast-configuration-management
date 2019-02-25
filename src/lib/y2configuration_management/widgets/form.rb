# encoding: utf-8

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
require "y2configuration_management/salt/form_element_locator"

module Y2ConfigurationManagement
  module Widgets
    # Widget which represents a Salt Formula Form
    #
    # This acts as a container for those all the widgets that are related to a formula
    # and takes care of:
    #
    # * Initializing the included widgets (see #value)...
    # * and storing the final result (see #store and #result).
    # It is able
    class Form < ::CWM::CustomWidget
      # @return [PagerTree] Widgets included in the form
      attr_reader :tree_pager
      # @return [Hash] Form values from included widgets when this one is removed from the UI
      attr_reader :result
      # @return [String] Form title
      attr_accessor :title

      # @example Setting values for included widgets
      #   form.value = { "name" => "John", "surname" => "Doe" }
      # @example Setting values for nested widgets
      #   form.value = { "ranges" => [ { "start" => "10.0.0.10", "end" => "10.0.0.20" } ] }
      attr_accessor :value

      # Constructor
      #
      # A form stores a set of keys and values.
      #
      # @example Regular form
      #   form.value = { "name" => "John Doe" }
      #   form.store
      #   form.result #=> { "name" => "John Doe" }
      #
      # @example Scalar form
      #   form.value = "John Doe"
      #   form.store
      #   form.result #=> "John Doe"
      #
      # @param tree_pager [PagerTree] Widgets included in the form
      # @param controller [Salt::FormController] Form controller
      # @param title      [String] Form title
      def initialize(tree_pager, controller, title: "")
        @value = {}
        @tree_pager = tree_pager
        @controller = controller
        @title = title
        self.handle_all_events = true
        super()
      end

      # This method propagates the values to the underlying widgets.
      # The values are defined using the `#value=` method.
      #
      # @see CWM::AbstractWidget#init
      def init
        set_children_contents
      end

      # Widget's content
      #
      # @see CWM::AbstractWidget
      def contents
        VBox(tree_pager)
      end

      # Stores the widget's value
      #
      # The stored value can be obtained using the #result method even
      # after the widget has been removed from the UI.
      #
      # @see CWM::AbstractWidget
      def store
        tree_pager.store
        @result = current_values
      end

      # Returns widget's content
      #
      # @return [Hash] values including the ones from the underlying widgets; values are
      #   `nil` when the form has been removed from the UI.
      def current_values
        tree_pager.value
      end

      # Refreshes the widget's content
      #
      # @param values [Hash] New values
      def refresh(values)
        self.value = values
        @result = nil
        set_children_contents
      end

      def handle
        @controller.update_visibility
        nil
      end

      def update_visibility(data)
        widgets.each do |widget|
          widget.update_visibility(data) if widget.respond_to? :update_visibility
        end
      end

      def relative_locator
        Y2ConfigurationManagement::Salt::FormElementLocator.new([])
      end

      # Return all widgets
      #
      # @return [Array<::CWM::AbstractWidget>]
      def widgets
        tree_pager.widgets
      end

    private

      def set_children_contents
        tree_pager.refresh(value)
      end
    end
  end
end
