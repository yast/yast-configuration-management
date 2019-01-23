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
    # This class is responsible for reading the form data from its definition and a data pillar.
    #
    # The format used in the pillar is slightly different from the internal representation of this
    # module, so this class takes care of the conversion. However, the initial intentation is to not
    # use it directly but through the {FormDate.from_pillar} class method.
    class FormDataReader
      # @return [Form] Form definition
      attr_reader :form
      # @return [Pillar]
      attr_reader :pillar

      # Constructor
      #
      # @param form   [Form] Form definition
      # @param pillar [Pillar] Pillar to read the data from
      def initialize(form, pillar)
        @pillar = pillar
        @form = form
      end

      # Builds a FormData object containing the form data
      #
      # @return [FormData] Form data object
      def form_data
        data_from_pillar = data_for_element(form.root, pillar.data)
        FormData.new(form, data_from_pillar)
      end

    private

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
    end
  end
end
