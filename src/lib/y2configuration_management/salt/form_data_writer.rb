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
        data_for_pillar(form_data.value)
      end

    private

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
        elsif first.respond_to?(:key?) && first.key?("$value")
          scalar_collection_for_pillar(collection)
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
          val = new_item.delete("$value") || data_for_pillar(new_item)
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
    end
  end
end
