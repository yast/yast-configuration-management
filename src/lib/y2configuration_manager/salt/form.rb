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

require "yaml"

module Y2ConfigurationManager
  module Salt
    # Class that represents a form for Salt Formulas
    class Form
      attr_reader :elements
      attr_reader :name
      attr_reader :type
      attr_reader :spec

      # Constructor
      #
      # @param name [String]
      # @param spec [Hash]
      def initialize(name, spec)
        @elements = []
        @name = name
        @spec = spec
        @type = spec["$type"]
        build_elements
      end

      # Instantiate a new form reading the definition from a YAML file
      #
      # param path [String] file path to read the form YAML definition
      def self.from_file(path)
        definition = YAML.load(File.read(path))
        name = definition.keys.first
        f = new(name, definition[name])
      end

    private

      def element_attributes
        spec.select { |k, v| !k.start_with?("$") }
      end

      def attributes
        spec.select { |k, v| k.start_with?("$") }
      end

      def build_elements
        element_attributes.each { |n, h| elements << FactoryFormElement.build(n, h) }
      end
    end

    class FactoryFormElement
      def self.build(name, spec)
        class_for(spec["$type"]).new(name, spec)
      end

      def self.class_for(type)
        case type
        when "namespace", "hidden-group", "group"
          Container
        when "edit-group"
          Collection
        else
          FormInput
        end
      end
    end

    # Three different kind of elements:
    #
    # scalar values, groups and collections
    class FormElement
      attr_reader :parent
      attr_reader :name, :help, :scope, :optional

      def initialize(name, spec)
        @name = name
        @type = spec["$type"] || "text"
        @help = spec["$help"] if spec ["$help"]
        @scope = spec["$scope"] if spec["$scope"]
        @optional = spec["$optional"] if spec["$optional"]
      end
    end

    class FormInput < FormElement
      attr_reader :type, :placeholder
      attr_reader :default, :values

      def initialize(name, spec)
        @values = spec["$values"] if spec["$values"]
        @placeholder = spec["$placeholder"] if spec["$placeholder"]
        super
      end
    end

    class Container < FormElement
      attr_reader :elements

      def initialize(name, spec)
        super
        @elements = []
        build_elements(spec)
      end

    private

      def build_elements(spec)
        spec.select { |k, v| !k.start_with?("$") }.map do |name, spec|
          @elements << FactoryFormElement.build(name, spec)
        end
      end
    end

    class Collection < FormElement
      attr_reader :min_items, :max_items, :item_name
      # list of elements (let's see if we promote it to a class)
      # or children or whatever:xs:xa
      attr_reader :prototype, :default

      def initialize(name, spec)
        super
        @item_name = spec["item_name"] if spec["item_name"]
        @min_items = spec["$minItems"] if spec["$minItems"]
        @max_items = spec["$maxItems"] if spec["$maxItems"]
        @prototype = prototype_for(name, spec)
        @default = spec["$default"] if spec["$default"]
      end

    private

      def prototype_for(name, spec)
        return unless spec["$prototype"]

        form_element = FactoryFormElement.build(name, spec["$prototype"])
        return form_element if [FormInput, Container].include?(form_element.class)

        spec["$prototype"].select { |k, v| !k.start_with?("$") }.map do |name, spec|
          FactoryFormElement.build(name, spec)
        end
      end
    end
  end
end
