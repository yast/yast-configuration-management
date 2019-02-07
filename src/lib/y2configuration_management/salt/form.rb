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
require "yast"
require "y2configuration_management/salt/form_condition"
require "y2configuration_management/salt/form_element_locator"
require "y2configuration_management/salt/form_element_factory"
require "y2configuration_management/salt/form_element_helpers"

module Y2ConfigurationManagement
  module Salt
    # A [Form][1] for [Salt Formulas][2].
    #
    # [1]: https://www.suse.com/documentation/suse-manager-3/3.2/susemanager-best-practices/html/book.suma.best.practices/best.practice.salt.formulas.and.forms.html#best.practice.salt.formulas.pillar
    # [2]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Form
      include Yast::Logger
      # @return [Container]
      attr_reader :root
      # @return [Hash] The original specification (deserialized form.yml).
      attr_reader :spec

      # Constructor
      #
      # The original specification (deserialized form.yml).
      #
      # @param spec [Hash] The original specification (deserialized form.yml).
      def initialize(spec)
        @root = Container.new("root", spec, parent: nil)
        @spec = spec
      end

      # Creates a new Form object reading the definition from a YAML file
      #
      # @param path [String] file path to read the form YAML definition
      # @return [Form, nil]
      def self.from_file(path)
        return nil unless File.exist?(path)
        definition = YAML.safe_load(File.read(path))
        new(definition)
      rescue IOError, SystemCallError, RuntimeError => error
        log.error("Reading #{path} failed with exception: #{error.inspect}")
        nil
      end

      # Recursively looks for a particular {FormElement}
      #
      # @example look for a FormElement by a specific name, locator or id
      #
      #   f = Y2ConfigurationManagemenet.from_file("form.yml")
      #   f.find_element_by(name: "subnets") #=> <Collection @name="subnets">
      #   locator = FormElementLocator.from_string("root#dhcpd")
      #   f.find_element_by(locator: locator) #=> <Container @name="dhcpd">
      #   f.find_element_by(id: "hosts") #=> <Container @id="hosts">
      #
      # @param arg [Hash]
      # @return [FormElement, nil]
      def find_element_by(arg)
        root.find_element_by(arg)
      end
    end

    # Three different kind of elements:
    #
    # scalar values, groups and collections
    class FormElement
      include FormElementHelpers
      # @return [String] the key for the pillar
      attr_reader :id
      # @return [Symbol]
      attr_reader :type
      # @return [FormElement]
      attr_reader :parent
      # @return [String] The user visible name ($name)
      attr_reader :name
      alias_method :label, :name
      # @return [String]
      attr_reader :help
      # @return [Symbol] specify the level in which the value can be edited.
      #   Possible values are: system, group and readonly
      attr_reader :scope
      # @return [Boolean]
      attr_reader :optional
      # @return [FormCondition,nil]
      attr_reader :visible_if

      # Constructor
      #
      # @param id [String]
      # @param spec [Hash] form element specification
      def initialize(id, spec, parent:)
        @id = id
        @name = spec.fetch("$name", humanize(id))
        @type = type_for(spec)
        @help = spec["$help"] if spec ["$help"]
        @scope = spec.fetch("$scope", "system").to_sym
        @optional = spec["$optional"] if spec["$optional"]
        @parent = parent
        @visible_if = FormCondition.parse(spec.fetch("$visibleIf", ""))
      end

      # Return the absolute locator of this form element in the actual form
      #
      # @return [FormElementLocator]
      def locator
        return FormElementLocator.new([id.to_sym]) if parent.nil?
        return parent.locator if parent.is_a?(Collection)
        parent.locator.join(id.to_sym)
      end

    private

      # "foo" -> "Foo"
      # "suse--fancy_salt_test" -> "Suse Fancy Salt Test"
      def humanize(s)
        s.split(/[-_]/).reject(&:empty?).map(&:capitalize).join(" ")
      end

      # Returns the type for a given form element specification
      #
      # @param spec [Hash] Form element specification
      # @return [Symbol] Form element type
      def type_for(spec)
        if spec["$type"] == "text" && spec.key?("$key") && form_elements_in(spec).size <= 1
          :key_value
        else
          spec.fetch("$type", "text").to_sym
        end
      end
    end

    # Scalar value FormElement
    class FormInput < FormElement
      # @return [String] help text usually displayed in the input field
      attr_reader :placeholder
      # @return [Boolean, Integer, String, nil] default input value
      attr_reader :default
      # @return [Array<String>] a list of possible values for a select input
      attr_reader :values

      # Constructor
      #
      # @param id [String]
      # @param spec [Hash] form element specification
      # @param parent [FormElement]
      def initialize(id, spec, parent:)
        @values = spec["$values"] if spec["$values"]
        @placeholder = spec["$placeholder"] if spec["$placeholder"]
        @default = spec["$default"]
        super
      end

      # Determines whether the input matches search criteria
      #
      # This method has been implemented here to keep FormElement classes API consistent.
      #
      # @param arg [Hash]
      # @return [FormInput, nil]
      # @see Form#find_element_by
      def find_element_by(arg)
        return self if arg.any? { |k, v| public_send(k) == v }
        nil
      end

      # Determines whether the input is a collection key
      #
      # In hash based collections, there is an special attribute called `$key` whose value is used
      # as collection index.
      #
      # @return [Boolean]
      def collection_key?
        id == "$key"
      end
    end

    # Container Element
    class Container < FormElement
      # @return [Array<FormElement>]
      attr_reader :elements

      # Constructor
      #
      # @param id [String]
      # @param spec [Hash] form element specification
      # @param parent [FormElement]
      def initialize(id, spec, parent:)
        super
        @elements = []
        build_elements(spec)
      end

      # Recursively looks for a particular {FormElement}
      #
      # @param arg [Hash]
      # @return [FormElement, nil]
      # @see Form#find_element_by
      def find_element_by(arg)
        return self if arg.any? { |k, v| public_send(k) == v }

        elements.each do |element|
          return element if arg.any? { |k, v| element.public_send(k) == v }
          if element.respond_to?(:find_element_by)
            nested_element = element.find_element_by(arg)
            return nested_element if nested_element
          end
        end

        nil
      end

    private

      # @param spec [Hash] form element specification
      def build_elements(spec)
        form_elements_in(spec).each do |id, nested_spec|
          @elements << FormElementFactory.build(id, nested_spec, parent: self)
        end
      end
    end

    # Defines a collection of {FormElement}s or {Container}s all of them based in
    # the same prototype.
    class Collection < FormElement
      # @return [Integer] lowest number of elements that needs to be defined
      attr_reader :min_items

      # @return [Integer] highest number of elements that needs to be defined
      attr_reader :max_items

      # @return [String] name for the members of the collection
      attr_reader :item_name

      # list of elements (let's see if we promote it to a class)
      # or children or whatever
      attr_reader :prototype

      # Default collection values
      attr_reader :default

      # Constructor
      #
      # @param id [String]
      # @param spec [Hash] form element specification
      # @param parent [FormElement]
      def initialize(id, spec, parent:)
        super
        @item_name = spec["item_name"] if spec["item_name"]
        @min_items = spec["$minItems"] if spec["$minItems"]
        @max_items = spec["$maxItems"] if spec["$maxItems"]
        @prototype = prototype_for(id, spec)
        @default = spec.fetch("$default", [])
      end

      # Recursively looks for a particular {FormElement}
      #
      # @param arg [Hash]
      # @return [FormElement, nil]
      # @see Form#find_element_by
      def find_element_by(arg)
        Array(prototype).each do |element|
          nested_element = element.find_element_by(arg)
          return nested_element if nested_element
        end

        nil
      end

      # Determines whether the collection is indexed by a key (instead of a numeric index)
      #
      # @return [Boolean] true if the collection uses a key; false otherwise
      def keyed?
        return false if prototype.nil? || !prototype.respond_to?(:elements)
        prototype.elements.any? { |e| e.respond_to?(:collection_key?) && e.collection_key? }
      end

      # Determines whether the collection has scalar values (with or without keys)
      #
      # @return [Boolean] `true` if it is an scalar collection
      #
      # @see simple_scalar?
      # @see keyed_scalar?
      def scalar?
        prototype.is_a?(FormInput)
      end

      # Determines whether the collection is an scalar one without index
      #
      # @return [Boolean] true if the collection is an scalar one; false otherwise
      def simple_scalar?
        return false if prototype.nil?
        scalar? && prototype.type != :key_value
      end

      # Determines whether the collection is a hash with scalar values
      #
      # @return [Boolean] true if the collection is a hash with scalar values; false otherwise
      def keyed_scalar?
        return false if prototype.nil?
        scalar? && prototype.type == :key_value
      end

    private

      # Return a single or group of {FormElement}s based on the prototype given
      # in the form specification
      #
      # @param id [String]
      # @param spec [Hash] form element specification
      def prototype_for(id, spec)
        return unless spec["$prototype"]

        if spec["$prototype"]["$type"] || spec["$prototype"].any? { |k, _v| !k.start_with?("$") }
          form_element = FormElementFactory.build(id, spec["$prototype"], parent: self)
          return form_element if [FormInput, Container].include?(form_element.class)
        end

        spec["$prototype"].select { |k, _v| !k.start_with?("$") }.map do |element_id, element_spec|
          FormElementFactory.build(element_id, element_spec, parent: self)
        end
      end
    end
  end
end
