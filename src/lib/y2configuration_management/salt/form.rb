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

module Y2ConfigurationManagement
  module Salt
    # A [Form][1] for [Salt Formulas][2].
    #
    # [1]: https://www.suse.com/documentation/suse-manager-3/3.2/susemanager-best-practices/html/book.suma.best.practices/best.practice.salt.formulas.and.forms.html#best.practice.salt.formulas.pillar
    # [2]: https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html
    class Form
      # @return Container
      attr_reader :root
       # The original specification (deserialized form.yml).
      attr_reader :spec

      # Constructor
      #
      # The original specification (deserialized form.yml).
      def initialize(spec)
        @root = Container.new("root", spec, parent: nil)
        @spec = spec
      end

      # Creates a new Form object reading the definition from a YAML file
      #
      # param path [String] file path to read the form YAML definition
      def self.from_file(path)
        definition = YAML.load(File.read(path))
        new(definition)
      end

      # Convenience method for looking for a particular FormElement.
      def find_element_by(arg)
        root.find_element_by(arg)
      end
    end

    # It builds new Form Elements depending on its specification type
    class FormElementFactory
      # Builds a new FormElement object based on the element specification and
      # maintaining a reference to its parent
      #
      # @param name [String]
      # @param spec [Hash]
      # @param parent [Form, FormElement]
      def self.build(name, spec, parent: )
        class_for(spec["$type"]).new(name, spec, parent: parent)
      end

      # @param type [String]
      # @return [FormElement]
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
      PATH_DELIMITER = ".".freeze
      # @return [String]
      attr_reader :id
      # @return [Symbol]
      attr_reader :type
      # @return [FormElement]
      attr_reader :parent
      # @return  [String]
      attr_reader :name
      # @return [String]
      attr_reader :help
      # @return [Symbol] specify the level in which the value can be edited.
      #   Possible values are: system, group and readonly
      attr_reader :scope
      # @return optional [Boolean]
      attr_reader :optional

      # Constructor
      #
      # @param name [String]
      # @param spec [Hash] form element specification
      def initialize(name, spec, parent:)
        @id = name
        @name = spec.fetch("$name", name)
        @type = spec.fetch("$type", "text").to_sym
        @help = spec["$help"] if spec ["$help"]
        @scope = spec.fetch("$scope", "system").to_sym
        @optional = spec["$optional"] if spec["$optional"]
        @parent = parent
      end

      # Return the absolute path of this form element in the actual form
      #
      # FIXME: possible implementation of the form element path
      #
      # @return [String]
      def path
        prefix = parent ? parent.path : ""
        return "#{prefix}#{PATH_DELIMITER}#{id}"
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
      # @param name [String]
      # @param spec [Hash] form element specification
      # @param parent [FormElement]
      def initialize(name, spec, parent:)
        @values = spec["$values"] if spec["$values"]
        @placeholder = spec["$placeholder"] if spec["$placeholder"]
        super
      end
    end

    # Container Element
    class Container < FormElement
      # @return elements [Array<FormElement>]
      attr_reader :elements

      # Constructor
      #
      # @param name [String]
      # @param spec [Hash] form element specification
      # @param parent [FormElement]
      def initialize(name, spec, parent:)
        super
        @elements = []
        build_elements(spec)
      end

      # Recursively looks for a particular FormElement
      #
      # @example look for a FormElement by a specific name
      #
      #   f = Y2ConfigurationManagemenet.from_file("form.yml")
      #   f.find_element_by(name: "subnets") #=> <Collection @name="subnets"
      #   f.find_element_by(path: ".root.dhcpd") #=> <Container @name="dhcpd"
      #
      # @param arg [Hash]
      # @return [FormElement, nil]
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
        spec.select { |k, v| !k.start_with?("$") }.each do |name, spec|
          @elements << FormElementFactory.build(name, spec, parent: self)
        end
      end
    end

    # Defines a collection of FormElements or Containers all of them based in
    # the same prototype.
    class Collection < FormElement
      # @return [Integer] lowest number of elements that needs to be defined
      attr_reader :min_items
      # @return [Integer] highest number of elements that needs to be defined
      attr_reader :max_items
      # @return [String] name for the members of the collection
      attr_reader :item_name
      # list of elements (let's see if we promote it to a class)
      # or children or whatever:xs:xa
      attr_reader :prototype

      # Default collection values
      attr_reader :default

      # Constructor
      #
      # @param name [String]
      # @param spec [Hash] form element specification
      # @param parent [FormElement]
      def initialize(name, spec, parent:)
        super
        @item_name = spec["item_name"] if spec["item_name"]
        @min_items = spec["$minItems"] if spec["$minItems"]
        @max_items = spec["$maxItems"] if spec["$maxItems"]
        @prototype = prototype_for(name, spec)
        @default = spec["$default"] if spec["$default"]
      end

    private

      # Return a single or group of FormElements based on the prototype given
      # in the form specification
      #
      # @param name [String]
      # @param spec [Hash] form element specification
      def prototype_for(name, spec)
        return unless spec["$prototype"]

        if spec["$prototype"]["$type"] || spec["$prototype"].any? { |k, v| !k.start_with?("$") }
          form_element = FormElementFactory.build(name, spec["$prototype"], parent: self)
          return form_element if [FormInput, Container].include?(form_element.class)
        end

        spec["$prototype"].select { |k, _v| !k.start_with?("$") }.map do |element_id, element_spec|
          FormElementFactory.build(element_id, element_spec, parent: self)
        end
      end
    end
  end
end
