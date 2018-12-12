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
      PATH_DELIMITER = ".".freeze
      # @return [Y2ConfigurationManagement::Salt::Form] Form
      attr_reader :form
      # @return [Y2ConfigurationManagement::Salt::Pillar] Pillar
      attr_reader :pillar

      # Constructor
      #
      # @param form [Y2ConfigurationManagement::Salt::Form] Form
      # @param pillar [Y2ConfigurationManagement::Salt::Form] Pillar
      def initialize(form, pillar = Pillar.new({}))
        @data = data_for_form(form, pillar.data)
        @form = form
        @pillar = pillar
      end

      # Returns the value of a given element
      #
      # @param path [String] Path to the element
      def get(path, index = nil)
        value = @data.dig(*path_to_parts(path)) || default_for(path)
        index ? value.at(index) : value
      end

      # Updates an element's value
      #
      # @param path  [String] Path to the collection
      # @param value [Object] New value
      def update(path, value)
        parts = path_to_parts(path)
        parent_parts = parts[0..-2]
        parent = @data
        parent = parent.dig(* parent_parts) unless parent_parts.empty?
        parent[parts.last] = value
      end

      # Adds an element to a collection
      #
      # @param path  [String] Path to the collection
      # @param value [Hash] Value to add
      def add_item(path, value)
        collection = get(path)
        collection.push(value)
      end

      # @param path  [String]  Path to the collection
      # @param index [Integer] Position of the element to remove
      # @param value [Object] New value
      def update_item(path, index, value)
        collection = get(path)
        collection[index] = value
      end

      # Removes an element from a collection
      #
      # @param path  [String]  Path to the collection
      # @param index [Integer] Position of the element to remove
      def remove_item(path, index)
        collection = get(path)
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
      # @param path [String] Element path
      def default_for(path)
        element = form.find_element_by(path: path)
        element ? element.default : nil
      end

      # Split the path into different parts
      #
      # @param path [String] Element path
      def path_to_parts(path)
        path[1..-1].split(PATH_DELIMITER)
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
          # TODO: we probably should remove the .root path prefix
          value = data.dig(*path_to_parts(element.path.gsub(/^\.(root)?/, "")))
          { element.id => value.nil? ? element.default : value }
        end
      end
    end
  end
end
