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
      # @return [Array<CWM::AbstractWidget>] Widgets included in the form
      attr_reader :children
      # @return [Hash] Form values from included widgets when this one is removed from the UI
      attr_reader :result

      # @example Setting values for included widgets
      #   form.value = { "name" => "John", "surname" => "Doe" }
      # @example Setting values for nested widgets
      #   form.value = { "ranges" => [ { "start" => "10.0.0.10", "end" => "10.0.0.20" } ] }
      attr_accessor :value

      # Constructor
      #
      # @param children [Array<CWM::AbstractWidget>] Widgets included in the form
      def initialize(children, controller)
        @children = children
        @controller = controller
        @value = {}
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
        VBox(*children)
      end

      # Stores the widget's value
      #
      # The stored value can be obtained using the #result method even
      # after the widget has been removed from the UI.
      #
      # @see CWM::AbstractWidget
      def store
        @result = current_values
      end

      # Returns widget's content
      #
      # @return [Hash,nil] values including the ones from the underlying widgets; nil when
      #   the widget has been removed from the UI.
      def current_values
        children.reduce({}) { |a, e| a.merge(e.id => e.value) }
      end

      # Refreshes the widget's content
      #
      # @param values [Hash] New values
      def refresh(values)
        self.value = values
        set_children_contents
      end

      def handle
        @controller.update_visibility
        nil
      end

      def update_visibility(data)
        children.each do |widget|
          widget.update_visibility(data)
        end
      end

    private

      def set_children_contents
        set_children_contents_precond!
        children.each do |widget|
          widget.value = value[widget.id] if value[widget.id]
        end
      end

      def set_children_contents_precond!
        child_ids = children.map(&:id).sort
        value_keys = value.keys.sort
        return if child_ids == value_keys
        raise "Form expects ids #{child_ids}, got #{value_keys}"
      end
    end
  end
end
