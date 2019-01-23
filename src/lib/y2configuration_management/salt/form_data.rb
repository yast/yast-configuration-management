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
        find_by_locator(@data, locator) || default_for(locator)
      end

      # Updates an element's value
      #
      # @param locator [FormElementLocator] Locator of the collection
      # @param value   [Object] New value
      def update(locator, value)
        parent = get(locator.parent)
        parent[key_for(locator.last)] = value
      end

      # Adds an element to a collection
      #
      # @param locator [FormElementLocator] Locator of the collection
      # @param value   [Object] Value to add
      def add_item(locator, value)
        collection = get(locator)
        collection.push(value)
      end

      # @param locator [FormElementLocator] Locator of the collection
      # @param value   [Object] New value
      def update_item(locator, value)
        collection = get(locator.parent)
        collection[key_for(locator.last)] = value
      end

      # Removes an element from a collection
      #
      # @param locator [FormElementLocator] Locator of the collection
      def remove_item(locator)
        collection = get(locator.parent)
        collection.delete_at(locator.last)
      end

      # Returns a hash containing the form data
      #
      # @return [Hash]
      def to_h
        data_for_pillar(@data)
      end

    private

      # Recursively finds a value
      #
      # @param data    [Hash,Array] Data structure to search for the value
      # @param locator [FormElementLocator] Value locator
      # @return [Object] Value
      def find_by_locator(data, locator)
        return nil if data.nil?
        return data if locator.first.nil?
        key = locator.first
        next_data =
          if key.is_a?(String)
            data.find { |e| e["$key"] == key }
          else
            data[key_for(key)]
          end
        find_by_locator(next_data, locator.rest)
      end

      # Default value for a given element
      #
      # @param locator [FormElementLocator] Element locator
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
          value = find_in_pillar_data(data, element.locator.rest) # FIXME: remove '.root'
          value ||= element.default
          { element.id => data_from_pillar_collection(value, element) }
        end
      end

      # Converts from a Pillar collection into form data
      #
      # Basically, a collection might be an array or a hash. The internal representation, however,
      # is always an array, so it is needed to do the conversion.
      #
      # @param element [Y2ConfigurationManagement::Salt::FormElement]
      # @param value   [Array,Hash]
      # @return
      def data_from_pillar_collection(collection, element)
        return nil if collection.nil?
        return collection unless element.respond_to?(:keyed?) && element.keyed?
        collection.map do |k, v|
          { "$key" => k }.merge(v)
        end
      end

      # Finds a value within a Pillar
      #
      # @todo This API might be available through the Pillar class.
      #
      # @param data    [Hash,Array] Data structure from the Pillar
      # @param locator [FormElementLocator] Value locator
      # @return [Object] Value
      def find_in_pillar_data(data, locator)
        return nil if data.nil?
        return data if locator.first.nil?
        key = locator.first
        key = key.is_a?(Symbol) ? key.to_s : key
        find_in_pillar_data(data[key], locator.rest)
      end

      # Returns data in a format to be used by the Pillar
      #
      # @param data [Object]
      # @return [Object]
      def data_for_pillar(data)
        case data
        when Array
          collection_for_pillar(data)
        when Hash
          hash_for_pillar(data)
        else
          data
        end
      end

      # Recursively converts a hash into one suitable to be used in a Pillar
      #
      # @param data [Hash]
      # @return [Hash]
      def hash_for_pillar(data)
        data.reduce({}) do |all, (k, v)|
          value = data_for_pillar(v)
          next all if value.nil?
          all.merge(k.to_s => value)
        end
      end

      # Converts a collection to be used in a Pillar
      #
      # Arrays containing hashes with a `$key` element will be converted into a hash
      # using the `$key` values as hash keys. See #hash_collection_for_pillar.
      #
      # @param collection [Array]
      # @return [Array,Hash]
      def collection_for_pillar(collection)
        first = collection.first
        return [] if first.nil?
        if first.respond_to?(:key?) && first.key?("$key")
          hash_collection_for_pillar(collection)
        else
          collection.map { |d| data_for_pillar(d) }
        end
      end

      # Converts a collection into a hash to be used in a Pillar
      #
      # @param collection [Array<Hash>] This method expects an array containing hashes which include
      #   `$key` element.
      # @return [Array,Hash]
      def hash_collection_for_pillar(collection)
        collection.reduce({}) do |all, item|
          new_item = item.clone
          key = new_item.delete("$key")
          all.merge(key => data_for_pillar(new_item))
        end
      end

      # Convenience method which converts a value to be used as key for a array or a hash
      #
      # @param [String,Symbol,Integer]
      # @return [String,Integer]
      def key_for(key)
        key.is_a?(Symbol) ? key.to_s : key
      end
    end
  end
end
