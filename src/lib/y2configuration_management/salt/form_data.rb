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

module Y2ConfigurationManagement
  module Salt
    # This class holds data for a given Salt Formula Form
    #
    # @todo The support for collections is rather simple and nesting collections is not supported.
    #       We might consider using JSON Patch to modify the data.
    class FormData
      LOCATOR_DELIMITER = ".".freeze
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
      def get(locator, index = nil)
        value = @data.dig(*locator_to_parts(locator))
        value = default_for(locator) if value.nil?
        index ? value.at(index) : value
      end

      # Updates an element's value
      #
      # @param locator  [String] Locator of the collection
      # @param value [Object] New value
      def update(locator, value)
        parts = locator_to_parts(locator)
        parent_parts = parts[0..-2]
        parent = @data
        parent = parent.dig(* parent_parts) unless parent_parts.empty?
        parent[parts.last] = value
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
      # @param index [Integer] Position of the element to remove
      # @param value [Object] New value
      def update_item(locator, index, value)
        collection = get(locator)
        collection[index] = value
      end

      # Removes an element from a collection
      #
      # @param locator  [String]  Locator of the collection
      # @param index [Integer] Position of the element to remove
      def remove_item(locator, index)
        collection = get(locator)
        collection.delete_at(index)
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

      # Split the locator into different parts
      #
      # @param locator [String] Element locator
      def locator_to_parts(locator)
        locator[1..-1].split(LOCATOR_DELIMITER)
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
          # TODO: we probably should remove the .root locator prefix
          value = data.dig(*locator_to_parts(element.locator.gsub(/^\.(root)?/, "")))
          { element.id => value.nil? ? element.default : value }
        end
      end
    end
  end
end
