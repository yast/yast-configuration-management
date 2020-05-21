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

require "cwm/tree_pager"

module Y2ConfigurationManagement
  module Widgets
    # This class associates a page with a tree pager instance
    #
    # Additionally, it offers mechanisms to store and retrieve data from the underlying pages.
    class PagerTreeItem < ::CWM::PagerTreeItem
      # @return [PagerTreeItem] Parent item
      attr_accessor :parent
      # @return [Tree] Tree where the item belongs
      attr_writer :tree
      # @return [Boolean] Determines whether this is a main page
      attr_accessor :main
      # @return [FormCondition,nil]
      attr_reader :visible_if
      # @return [FormLocator]
      attr_reader :locator

      # Constructor
      #
      # @param page [Page] Associated page
      # @param icon
      # rubocop:disable Metrics/ParameterLists
      def initialize(page, icon: nil, open: true, children: [], locator: nil, visible_if: nil)
        super(page, icon: icon, open: open, children: children)
        @locator = locator
        @visible_if = visible_if
        @visible = true
        items.each { |i| i.parent = self }
        page.tree_item = self
      end
      # rubocop:enable Metrics/ParameterLists

      # Returns the page id
      #
      # Convenience method to find out the associated page ID.
      #
      # @return [String]
      def page_id
        page.id
      end

      # Updates item visibility
      #
      # @param data [FormData]
      # @see #visible?
      def update_visibility(data)
        @visible =
          if parent && !parent.visible?
            false
          elsif visible_if
            visible_if.evaluate(data, context: self)
          else
            true
          end
        items.each { |i| i.update_visibility(data) }
      end

      # Determines whether the item should be visible in the tree
      #
      # If the item is not {visible?}, it is not shown in the tree.
      #
      # @return [Boolean]
      def visible?
        @visible
      end

      def relative_locator
        return Y2ConfigurationManagement::Salt::FormElementLocator.new([]) if main
        return parent.relative_locator.join(page.id.to_sym) if respond_to?(:parent) && parent
        Y2ConfigurationManagement::Salt::FormElementLocator.new([page.id.to_sym])
      end

      # Widgets values
      #
      # @return [Hash]
      def value
        my_values = page.value
        items.reduce(my_values) do |a, e|
          a.merge(e.page_id => e.value)
        end
      end

      # Set widgets values
      #
      # @param new_value [Hash,Array] New values for the underlying page
      def value=(new_value)
        if new_value.is_a?(Hash)
          page.value = new_value.reject { |_k, v| v.is_a?(Enumerable) }
          items.each do |item|
            item.value = new_value[item.page_id] if new_value[item.page_id]
          end
        else
          page.value = new_value
        end
      end

      # Returns the children items
      #
      # @return [Array<PagerTreeItem>]
      def items
        children.values
      end

      # Returns the tree where it belongs
      #
      # @return [Tree]
      def tree
        @tree || (parent && parent.tree)
      end

      # Returns the pager where it belongs
      #
      # @return [TreePager]
      def pager
        tree.pager
      end

      # Returns the UI term for the item
      #
      # @return [Yast::Term]
      def ui_term
        args = [Yast::Term.new(:id, id)]
        args << Yast::Term.new(:icon, icon) if icon
        args << label
        args << open
        args << children.values.select(&:visible?).map(&:ui_term)
        Yast::Term.new(:item, *args)
      end
    end
  end
end
