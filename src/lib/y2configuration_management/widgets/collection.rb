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
require "y2configuration_management/widgets/base_mixin"
require "y2configuration_management/widgets/visibility_switcher"
require "y2configuration_management/widgets/salt_visibility_switcher"

module Y2ConfigurationManagement
  # This module contains the widgets which are used to display forms for Salt formulas
  module Widgets
    # Represents a collection of elements
    #
    # This widget uses a table to display a collection of elements and offers
    # buttons to add, remove and edit them.
    class Collection < ::CWM::CustomWidget
      include BaseMixin
      attr_reader :min_items
      attr_reader :max_items
      attr_reader :controller

      # @return [Array<String>] Headers for the collection table
      attr_reader :headers

      # @return [Array<Object>] List of objects which are included in the collection
      attr_accessor :value

      include SaltVisibilitySwitcher

      # @return [Array<CWM::AbstractWidget>] Parent widget
      attr_accessor :parent

      # Constructor
      #
      # @param spec         [Salt::FormElement] Element specification
      # @param controller   [Salt::FormController] Form controller
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, controller, data_locator)
        textdomain "configuration_management"
        initialize_base(spec, data_locator)
        @controller = controller
        @min_items = spec.min_items
        @max_items = spec.max_items
        @headers, @headers_ids = headers_from_prototype(spec.prototype)
        self.widget_id = "collection:#{spec.id}"
        self.value = []
      end

      # Widget contents
      #
      # @return [Term]
      def contents
        VBox(
          Table(
            Id("table:#{locator}"),
            Opt(:notify, :immediate),
            Header(*headers),
            []
          ),
          HBox(
            HStretch(),
            PushButton(Id("#{widget_id}_add".to_sym), Yast::Label.AddButton),
            PushButton(Id("#{widget_id}_edit".to_sym), Yast::Label.EditButton),
            PushButton(Id("#{widget_id}_remove".to_sym), Yast::Label.RemoveButton)
          )
        )
      end

      # Sets the value
      #
      # @param items_list [Array<Hash>] Collection items
      def value=(items_list)
        return if items_list.nil?
        Yast::UI.ChangeWidget(Id("table:#{locator}"), :Items, format_items(items_list))
        @value = items_list
      end

      # Forces the widget to inspect all events
      #
      # @return [TrueClass]
      def handle_all_events
        true
      end

      # Events handler
      #
      # @todo Partially implemented only
      #
      # @param event [Hash] Event specification
      def handle(event)
        case event["ID"]
        when "#{widget_id}_add".to_sym
          controller.add(relative_locator)
        when "#{widget_id}_edit".to_sym
          controller.edit(relative_locator.join(selected_row)) if selected_row
        when "#{widget_id}_remove".to_sym
          controller.remove(relative_locator.join(selected_row)) if selected_row
        end

        nil
      end

    private

      # @return [Array<String>] Header identifiers
      attr_reader :headers_ids

      # Returns the index of the selected row
      #
      # @return [Integer,nil] Index of the selected row or nil if no row is selected
      def selected_row
        row_id = Yast::UI.QueryWidget(Id("table:#{locator}"), :CurrentItem)
        row_id ? row_id.to_i : nil
      end

      # Format the items list for the colletion table
      #
      # @return [Array<Array<String|Yast::Term>>]
      def format_items(items_list)
        items_list.each_with_index.map do |item, index|
          values = item.is_a?(Hash) ? format_hash_item(item) : [item]
          formatted_values = values.map { |v| format_value(v) }
          Item(Id(index.to_s), *formatted_values)
        end
      end

      # Returns the list of headers names and IDs from the prototype spec
      #
      # @param prototype [FormElement] Prototype definition
      def headers_from_prototype(prototype)
        els = if prototype.is_a? Salt::Container
          prototype.elements
        else
          [prototype]
        end
        names = els.map { |h| (h.name || h.id) }
        ids = els.map(&:id)
        [names, ids]
      end

      # Returns a value formatted to be shown in the table
      #
      # When an array is given, it returns a 'n items' message (where 'n' is the size of the array).
      # Otherwise, it returns a string representing the object.
      #
      # @param val [Object]
      # @return [String] String to show in the table
      def format_value(val)
        return val.to_s unless val.is_a?(Enumerable)
        # TRANSLATORS: empty list
        return _("No items") if val.empty?
        # TRANSLATORS: items count in a list
        format(n_("%s item", "%s items", val.size), val.size)
      end

      # Returns a list of the hash values to be shown in the table
      #
      # When it is a text dictionary it returns a formatted string with the
      # $key and the $value
      #
      # @return [Array<String>]
      def format_hash_item(item)
        if item.keys == ["$key", "$value"]
          ["#{item["$key"]}: #{item["$value"]}"]
        elsif item.keys == ["$value"]
          [item["$value"].to_s]
        else
          headers_ids.map { |h| item[h] }
        end
      end
    end
  end
end
