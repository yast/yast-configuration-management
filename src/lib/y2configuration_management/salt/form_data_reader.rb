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
require "date"
require "time"

module Y2ConfigurationManagement
  module Salt
    # This class is responsible for reading the form data from its definition and a data pillar.
    #
    # The format used in the pillar is slightly different from the internal representation of this
    # module, so this class takes care of the conversion. However, the initial intentation is to not
    # use it directly but through the {FormData.from_pillar} class method.
    #
    # ## Handling collections
    #
    # There might be different kind of collections:
    #
    # * (1) Array with simple values (strings, integers, etc).
    # * (2) Hash based collections which index is provided by the user.
    # * (3) Array of hashes. They allow a more complex collection.
    #
    # To simplify things in the UI layer, all collections are handled as arrays of hashes so, in (1)
    # and (2) cases, some conversion is needed.
    #
    # For (1), the data in the Pillar is just an array of simple values (numbers, strings, or
    # any other scalar value). Internally, it is converted to an array of hashes with just a
    # `$value` key:
    #
    #   [{ "$value" => "foo" }, { "$value" => "bar" }]
    #
    # In the (2) case, given an specification with three fields `$key`, `url`, and `license`, the
    # collection would be stored in the Pillar like this:
    #
    #   { "yast2" =>
    #     { "url" => "https://yast.opensuse.org", "license" => "GPL" }
    #   }
    #
    # But internally, it will be handled as an array:
    #
    #   [{ "$key" => "yast2", "url" => "https://yast.opensuse.org", "license" => "GPL" }]
    #
    # Something similar applies to hash based simple collections which are originally like this (it
    # is a hash where the keys are specified by the user):
    #
    #   { "vers" => "4", "timeout" => "0" }
    #
    # It will be converted to:
    #
    #   [{ "$key" => "vers", "$value" => "4" }, { "$key" => "timeout", "$value" => "0" }]
    class FormDataReader
      include Yast::Logger
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
        data_from_pillar = { "root" => hash_from_pillar(pillar.data, form.root.locator) }
        defaults = defaults_for_element(form.root)
        FormData.new(form, simple_merge(defaults, data_from_pillar))
      end

    private

      # Extracts data from the pillar
      #
      # @param data    [Hash] Pillar data
      # @param locator [FormElementLocator] Locator
      # @return [Hash<String, Object>]
      def data_from_pillar(data, locator)
        element = form.find_element_by(locator: locator.unbounded)
        case element
        when Collection
          collection_from_pillar(data, locator)
        when Container
          hash_from_pillar(data, locator)
        else
          scalar_from_pillar(data)
        end
      end

      # Reads a hash from the pillar for a given locator
      #
      # @param data    [Hash] Pillar data
      # @param locator [FormElementLocator] Element locator
      # @return [Hash<String, Object>]
      def hash_from_pillar(data, locator)
        data.reduce({}) do |all, (k, v)|
          all.merge(k => data_from_pillar(v, locator.join(k.to_sym)))
        end
      end

      # Reads a scalar value from the Pillar
      #
      # Dates and times are converted into strings because is the representation
      # used by the widgets.
      #
      # @return [value]
      def scalar_from_pillar(value)
        [Time, Date].include?(value.class) ? value.to_s : value
      end

      # Converts a collection from the pillar
      #
      # @param data    [Hash] Pillar data
      # @param locator [FormElementLocator] Element locator
      # @return [Array<Hash>]
      def collection_from_pillar(data, locator)
        element = form.find_element_by(locator: locator.unbounded)
        if element.keyed?
          data.map { |k, v| { "$key" => k }.merge(hash_from_pillar(v, locator.join(k))) }
        elsif element.keyed_scalar?
          data.map { |k, v| { "$key" => k, "$value" => v } }
        elsif element.simple_scalar?
          data.map { |v| { "$value" => v } }
        else
          data.map { |d| hash_from_pillar(d, locator) }
        end
      end

      # Extracts default values for a given element
      #
      # @param element [FormElement]
      # @return [Object]
      def defaults_for_element(element)
        case element
        when Container
          defaults = element.elements.reduce({}) { |a, e| a.merge(defaults_for_element(e)) }
          { element.id => defaults }
        when Collection
          { element.id => defaults_for_collection(element) }
        else
          { element.id => element.default }
        end
      end

      # Extracts default values for a given collection
      #
      # @param collection [Collection]
      # @return [Array<Hash>]
      def defaults_for_collection(collection)
        if collection.keyed?
          collection.default.map { |k, v| { "$key" => k }.merge(v) }
        elsif collection.prototype.is_a?(FormInput) && collection.prototype.type == :key_value
          collection.default.map { |k, v| { "$key" => k, "$value" => v } }
        else
          collection.default
        end
      end

      # Simple deep merge
      #
      # @param defaults [Hash] Default values
      # @param data [Hash] Pillar data
      def simple_merge(defaults, data)
        defaults.reduce({}) do |all, (k, v)|
          next all.merge(k => v) if data[k].nil?
          if v.is_a?(Hash)
            all.merge(k => simple_merge(defaults[k], data[k]))
          else
            all.merge(k => data[k])
          end
        end
      end
    end
  end
end
