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
require "cwm/tree_pager"
require "y2configuration_management/widgets/tree"

module Y2ConfigurationManagement
  module Widgets
    # This class implements a tree pager which allows to browse through the different parts of a
    # form.
    class TreePager < CWM::TreePager
      # @return [Array<Page>] Included pages
      attr_reader :pages

      # Constructor
      #
      # @param [Array<PagerTreeItem>] Items to include in the tree
      def initialize(items)
        textdomain "configuration_management"
        super(Tree.new(items, self))
      end

      # Switches current page
      #
      # @see CWM::TreePager
      def switch_page(page)
        current_page.store
        super(page)
      end

      # Refreshes the pages values
      #
      # @param value [Hash,Array] New values for the pages
      def refresh(value)
        self.value = value
        pages.each(&:init)
      end

      # First level tree items
      #
      # @note This method does not returns all items, just the ones in the first level
      #
      # @return [Array<PagerTreeItem>] Items
      def items
        tree.items
      end

      # Assigns values to the pages
      #
      # @param new_value [Hash,Array] Value to assign to the widgets
      def value=(new_value)
        items.first.value = new_value if items.first.main
        items.reject(&:main).each do |item|
          item.value = new_value[item.page_id] if new_value[item.page_id]
        end
      end

      # Returns the value from the widgets
      #
      # @return [Hash]
      def value
        base = items.first.main ? items.first.value : {}
        items.reject(&:main).reduce(base) { |a, e| a.merge(e.page_id => e.value) }
      end

      # Returns included widgets
      #
      # @return [Array<PagerTreeItem>]
      def widgets
        pages.flat_map(&:children)
      end

      # Widget's content
      #
      # @see CWM::AbstractWidget
      def contents
        MinSize(
          50, # FIXME: estimate needed sizes
          50,
          HBox(
            pages.size > 1 ? HWeight(30, tree) : Empty(),
            HWeight(70, replace_point),
            VStretch()
          )
        )
      end

    private

      # @return [Tree] Tree widget
      attr_reader :tree
    end
  end
end
