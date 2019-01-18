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

require "y2configuration_management/salt/pillar"

module Y2ConfigurationManagement
  module Salt
    # This class holds data for a given Salt Formula Form
    #
    # @todo The support for collections is rather simple and nesting collections is not supported.
    #       We might consider using JSON Patch to modify the data.
    class FormData
      # @return [Y2ConfigurationManagement::Salt::Form] Form
      attr_reader :form
      # @return [Y2ConfigurationManagement::Salt::Pillar] Pillar
      attr_reader :pillar

      # Constructor
      #
      # @param form [Y2ConfigurationManagement::Salt::Form] Form
      # @param pillar [Y2ConfigurationManagement::Salt::Form] Pillar
      def initialize(form, pillar = Pillar.new(data: {}))
        @data = data_for_form(form, pillar.data)
        @form = form
        @pillar = pillar
      end

      # Returns the value of a given element
      #
      # @param locator [String] Locator of the element
      def get(locator)
        value = find_by_locator(@data, locator)
        value = default_for(locator) if value.nil?
        value
      end

      # Updates an element's value
      #
      # @param locator  [String] Locator of the collection
      # @param value [Object] New value
      def update(locator, value)
        parent = get(locator.parent)
        parent[locator.last] = value
      end

      # Adds an element to a collection
      #
      # @param locator  [String] Locator of the collection
      # @param value [Hash] Value to add
      def add_item(locator, value)
        collection = get(locator)
        collection.push(value)
      end

      # @param locator  [String]  Locator of the collection
      # @param value [Object] New value
      def update_item(locator, value)
        collection = get(locator.parent)
        collection[locator.last] = value
      end

      # Removes an element from a collection
      #
      # @param locator  [String]  Locator of the collection
      def remove_item(locator)
        collection = get(locator.parent)
        collection.delete_at(locator.last)
      end

      # Returns a hash containing the form data
      #
      # @return [Hash]
      def to_h
        @data
      end

    private

      # Default value for a given element
      #
      # @param locator [String] Element locator
      def default_for(locator)
        element = form.find_element_by(locator: locator)
        element ? element.default : nil
      end

      # Builds a hash to keep the form data
      #
      # @param form [Y2ConfigurationManagement::Salt::Form]
      # @param data [Hash] Pillar data
      # @return [Hash]
      def data_for_form(form, data)
        data_for_element(form.root, data)
      end

      # Builds a hash to keep the form element data
      #
      # @param element [Y2ConfigurationManagement::Salt::FormElement]
      # @param data [Hash] Pillar data
      # @return [Hash]
      def data_for_element(element, data)
        if element.is_a?(Container)
          defaults = element.elements.reduce({}) { |a, e| a.merge(data_for_element(e, data)) }
          { element.id => defaults }
        else
          value = find_by_locator(data, element.locator.rest) # FIXME: remove '.root'
          { element.id => value.nil? ? element.default : value }
        end
      end

      # Finds a value
      #
      # @param data    [Hash,Array] Data structure to search for the value
      # @param locator [FormElementLocator] Value locator
      # @return [Object] Value
      def find_by_locator(data, locator)
        return nil if data.nil?
        return data if locator.first.nil?
        find_by_locator(data[locator.first], locator.rest)
      end
    end
  end
end
