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

require "y2configuration_management/salt/form"
require "y2configuration_management/salt/form_data"

module Y2ConfigurationManagement
  module Salt
    # This class is responsible for writing the form data into a pillar.
    #
    # @see FormDataReader
    class FormDataWriter
      # @return [Form] Form specification
      attr_reader :form
      # @return [Hash,Array] Current form data
      attr_reader :form_data

      # Constructor
      #
      # @param form [Form] Form specification
      # @param form_data [FormData] Current form data
      def initialize(form, form_data)
        @form = form
        @form_data = form_data
      end

      # Converts the form data into a structure suitable to use in the Pillar
      #
      # @return [Hash]
      def to_pillar_data
        data_for_pillar(form_data.value.fetch("root", {}), form.root)
      end

    private

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
    end
  end
end
