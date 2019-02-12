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

require "y2configuration_management/salt/form_data_reader"

module Y2ConfigurationManagement
  module Salt
    # This class holds data for a given Salt Formula Form
    class FormData
      # @return [Y2ConfigurationManagement::Salt::Form] Form
      attr_reader :form

      class << self
        # @param form   [Form] Form definition
        # @param pillar [Pillar] Pillar to read the data from
        # @return [FormData] Form data merging defaults and pillar values
        def from_pillar(form, pillar)
          FormDataReader.new(form, pillar).form_data
        end
      end

      # Constructor
      #
      # @param form    [Form] Form definition
      # @param initial [Hash] Initial data in hash form
      def initialize(form, initial = {})
        @form = form
        @data = initial
      end

      # Returns the value of a given element
      #
      # @param locator [FormElementLocator] Locator of the element
      def get(locator)
        value = find_by_locator(@data, locator)
        value = default_for(locator) if value.nil?
        value
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
        { "root" => data_for_pillar(@data["root"], form.root) }
      end

      # Returns a copy of this object
      #
      # @return [FormData]
      def copy
        self.class.new(form, Marshal.load(Marshal.dump(@data)))
      end

    private

      # Recursively finds a value
      #
      # @param data    [Hash,Array] Data structure to search for the value
      # @param locator [FormElementLocator] Value locator
      # @return [Object,nil] Found value; nil if no value was found for the given locator
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

      # Returns data in a format to be used by the Pillar
      #
      # @param data [Object]
      # @param element [FormElement] Form element corresponding to `data`
      # @return [Object]
      def data_for_pillar(data, element)
        return data if element.nil?
        case data
        when Array
          collection_for_pillar(data, element)
        when Hash
          hash_for_pillar(data, element)
        else
          scalar_for_pillar(data, element)
        end
      end

      # Recursively converts a hash into one suitable to be used in a Pillar
      #
      # @param data [Hash]
      # @param element [FormElement] Form element corresponding to `data`
      # @return [Hash]
      def hash_for_pillar(data, element)
        data.reduce({}) do |all, (k, v)|
          children = element.find_element_by(locator: element.locator.join(k.to_sym))
          value = data_for_pillar(v, children)
          next all if value.nil? && children && children.optional?
          all.merge(k.to_s => value)
        end
      end

      # Converts a collection to be used in a Pillar
      #
      # Arrays containing hashes with a `$key` element will be converted into a hash
      # using the `$key` values as hash keys. See #hash_collection_for_pillar.
      #
      # @param collection [Array]
      # @param element [FormElement] Form element corresponding to `data`
      # @return [Array,Hash]
      def collection_for_pillar(collection, element)
        first = collection.first
        return [] if first.nil?
        if first.respond_to?(:key?) && first.key?("$key")
          hash_collection_for_pillar(collection, element)
        elsif first.respond_to?(:key?) && first.key?("$value")
          scalar_collection_for_pillar(collection)
        else
          collection.map { |d| data_for_pillar(d, element) }
        end
      end

      # Converts a collection into a hash to be used in a Pillar
      #
      # @param collection [Array<Hash>] This method expects an array containing hashes which include
      #   `$key` element.
      # @param element [FormElement] Form element corresponding to `data`
      # @return [Array,Hash]
      def hash_collection_for_pillar(collection, element)
        collection.reduce({}) do |all, item|
          new_item = item.clone
          key = new_item.delete("$key")
          val = new_item.delete("$value") || data_for_pillar(new_item, element)
          all.merge(key => val)
        end
      end

      # Converts a collection into an array to be used in a Pillar
      #
      # @param collection [Array<Hash>] This method expects an array containing hashes which include
      #   `$value` element.
      # @return [Array]
      def scalar_collection_for_pillar(collection)
        collection.map { |i| i["$value"] }
      end

      # Converts a scalar value into its Pillar representation
      #
      # @param value [Object] Value to convert
      # @param element [FormElement] Form element corresponding to `data`
      # @return [Object]
      def scalar_for_pillar(value, element)
        return element.if_empty if value.to_s.empty?
        case element.type
        when :date
          Date.parse(value)
        when :datetime
          Time.parse(value)
        else
          value
        end
      rescue ArgumentError # Date.parse or Time.parse failed
        nil
      end

      # Convenience method which converts a value to be used as key for a array or a hash
      #
      # @param key [String,Symbol,Integer]
      # @return [String,Integer]
      def key_for(key)
        key.is_a?(Symbol) ? key.to_s : key
      end
    end
  end
end
