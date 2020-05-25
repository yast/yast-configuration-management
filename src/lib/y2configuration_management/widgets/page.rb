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
require "cwm/page"
require "y2configuration_management/widgets/collection"

module Y2ConfigurationManagement
  module Widgets
    # Represents a page including a set of elements
    #
    # Usually, groups and collections are displayed in its own page.
    class Page < ::CWM::Page
      # @return [String] Element id
      attr_reader :id
      # @return [Array<CWM::AbstractWidget>] Widgets to include in the page
      attr_reader :children
      # @return [Hash,Array] Page value
      attr_accessor :value
      # @return [PagerTreeItem] Tree item associated with the page
      attr_accessor :tree_item
      # @!attribute [w] value
      #   Values for widgets included in the page
      attr_writer :value

      # Constructor
      #
      # @param id       [String] Form element id
      # @param label    [String] Page title (shown in the tree)
      # @param children [Array<CWM::AbstractWidget>] Widgets to display
      def initialize(id, label, children)
        textdomain "configuration_management"

        @id = id
        @label = label
        add_children(*children)
        self.widget_id = "page:#{id}"
      end

      # Add widgets to the page
      #
      # @param widgets [Array<::CWM::AbstractWidget>] Widgets to add to the page
      def add_children(*widgets)
        @children ||= []
        widgets.each { |w| w.parent = self }
        @children.concat(widgets)
      end

      # Relative locator
      #
      # @return [FormElementLocator]
      def relative_locator
        tree_item.relative_locator
      end

      # @see CWM::AbstractWidget#init
      def init
        set_children_contents
      end

      # Widget's label
      #
      # @see CWM::AbstractWidget
      def label
        @label || @id
      end

      # Widget's content
      #
      # @see CWM::AbstractWidget
      def contents
        VBox(
          *children.map { |w| Left(w) },
          VStretch()
        )
      end

      # Stores the widget's value
      #
      # @todo This method does nothing when the page is not visible because, in such a case,
      #   widgets' values are `nil`.
      #
      # @see CWM::AbstractWidget
      def store
        @value = current_values if visible?
      end

      # TODO: rename to "selected?"
      # Determine whether this page is visible or not
      #
      # @return [Boolean] true if the page is visible; false otherwise.
      def visible?
        pager.current_page && pager.current_page.id == id
      end

      # Returns widget's content
      #
      # @return [Hash] values including the ones from the underlying widgets; values are
      #   `nil` when the form has been removed from the UI.
      def current_values
        if collection?
          children.first.value
        else
          children.reduce({}) { |a, e| a.merge(e.id => e.value) }
        end
      end

      # @return [Integer]
      def min_height
        children.map(&:min_height).sum
      end

      # Update children visibility
      #
      # @param data [FormData] Form data
      def update_visibility(data)
        children.each { |e| e.update_visibility(data) }
      end

    protected

      # Propagates the values to the underlying widgets
      #
      # The values are previously defined using the `#value=` method.
      def set_children_contents
        return if value.nil?
        if value.is_a?(Array)
          children.first.value = value
        else
          children.each do |widget|
            widget.value = value[widget.id] if value[widget.id]
          end
        end
      end

      # Returns the pager where the page belongs to
      #
      # @return [TreePager]
      def pager
        tree_item.pager
      end

      # Determines whether the page contains just a collection
      #
      # @return [Boolean]
      def collection?
        children.first.is_a?(Collection)
      end
    end
  end
end
