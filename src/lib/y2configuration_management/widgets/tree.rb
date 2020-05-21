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

module Y2ConfigurationManagement
  module Widgets
    # Tree widget to display the form sections
    #
    # It only shows visible entries (@see {PagerTreeItem#visible?}).
    class Tree < ::CWM::Tree
      # @return [Array<PagerTreeItem>] Included tree items
      attr_reader :items
      # @return [TreePager] Associated tree pager
      attr_reader :pager

      # Constructor
      #
      # @param items [Array<PagerTreeItem>] List of tree items
      # @param pager [TreePager] Tree pager where the tree belongs to
      def initialize(items, pager)
        textdomain "configuration_management"
        @pager = pager
        @items = items
        items.each { |i| i.tree = self }
      end

      # Widget's label
      #
      # @see CWM::AbstractWidget
      def label
        _("Sections")
      end

      # Tree's content
      #
      # It only shows the visible elements
      #
      # @return [Yast::Term]
      # @see PagerTreeItem#visible?
      def contents
        VBox(
          ReplacePoint(Id(:tree_items), tree_content)
        )
      end

      # Refreshes the tree content keeping the current item as selected
      def refresh
        return unless Yast::UI.WidgetExists(Id(widget_id))
        current_item = Yast::UI.QueryWidget(Id(widget_id), :CurrentItem)
        Yast::UI.ReplaceWidget(Id(:tree_items), tree_content)
        Yast::UI.ChangeWidget(Id(widget_id), :CurrentItem, current_item)
      end

    private

      # Returns the Tree term
      #
      # @return [Yast::Term]
      def tree_content
        item_terms = items.select(&:visible?).map(&:ui_term)
        Tree(Id(widget_id), Opt(:notify), label, item_terms)
      end
    end
  end
end
