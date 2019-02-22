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

      # Constructor
      #
      # @param page [Page] Associated page
      # @param icon 
      def initialize(page, icon: nil, open: true, children: [])
        super
        items.each { |i| i.parent = self }
        page.tree_item = self
      end

      # Returns the page id
      #
      # Convenience method to find out the associated page ID.
      #
      # @return [String]
      def page_id
        page.id
      end

      def relative_locator
        return Y2ConfigurationManagement::Salt::FormElementLocator.new([]) if main
        return parent.relative_locator.join(page.id.to_sym) if respond_to?(:parent) && parent
        Y2ConfigurationManagement::Salt::FormElementLocator.new([page.id.to_sym])
      end

      # Widgets values
      #
      # @note As a side effect, this method calls #store (FIXME)
      #
      # @return [Hash]
      def value
        page.store # needed for updating the visibility
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
    end
  end
end
