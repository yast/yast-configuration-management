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

require "y2configuration_management/widgets"

module Y2ConfigurationManagement
  module Salt
    # This class builds a form according to a given specification
    #
    # For further information, see the forms specification at
    # https://www.suse.com/documentation/suse-manager-3/3.2/susemanager-best-practices/html/book.suma.best.practices/best.practice.salt.formulas.and.forms.html
    class FormBuilder
      INPUT_WIDGET_CLASS = {
        color:     Y2ConfigurationManagement::Widgets::Color,
        text:      Y2ConfigurationManagement::Widgets::Text,
        number:    Y2ConfigurationManagement::Widgets::Text,
        email:     Y2ConfigurationManagement::Widgets::Email,
        password:  Y2ConfigurationManagement::Widgets::Password,
        url:       Y2ConfigurationManagement::Widgets::URL,
        select:    Y2ConfigurationManagement::Widgets::Select,
        boolean:   Y2ConfigurationManagement::Widgets::Boolean,
        date:      Y2ConfigurationManagement::Widgets::Date,
        datetime:  Y2ConfigurationManagement::Widgets::DateTime,
        time:      Y2ConfigurationManagement::Widgets::Time,
        key_value: Y2ConfigurationManagement::Widgets::KeyValue
      }.freeze

      # Constructor
      #
      # @param controller [FormController] Controller to inject in widgets
      def initialize(controller, form)
        @controller = controller
        @form = form
      end

      # Returns the list of widgets to be included in the form
      #
      # @param locator [FormElementLocator] Form element locator
      # @return [Widgets::Form] Form widget
      def build(locator)
        form_element = form.find_element_by(locator: locator.unbounded)
        form_element = form_element.prototype if form_element.is_a?(Collection)
        scalar = !form_element.respond_to?(:elements)
        root_locator = form_element.is_a?(Container) ? locator : locator.parent
        elements = scalar ? [form_element] : form_element.elements
        widgets = Array(elements).map { |e| build_element(e, root_locator) }
        Y2ConfigurationManagement::Widgets::Form.new(
          widgets, controller, scalar: scalar
        )
      end

    private

      # @return [FormController] Controller to inject in widgets
      attr_reader :controller
      # @return [FormElement] Form description
      attr_reader :form

      # Build a form element
      #
      # The form element can be a simple input control, a group or even a collection.
      # The type is determined by the `$type` key which should be included in the element
      # specification.
      #
      # @param element [Y2ConfigurationManagement::Salt::FormElement] Form element
      # @return [Y2ConfigurationManagement::Widgets::Group,
      #          Y2ConfigurationManagement::Widgets::Text,
      #          Y2ConfigurationManagement::Widgets::Collection]
      def build_element(element, locator)
        element_locator = locator.join(element.id.to_sym)
        case element.type
        when :group, :namespace, :"hidden-group"
          build_group(element, element_locator)
        when :"edit-group"
          build_collection(element, element_locator)
        when *INPUT_WIDGET_CLASS.keys
          build_input(element, element_locator)
        else
          raise "Unknown $type: #{element.type}"
        end
      end

      # Builds a form group
      #
      # @param group [Y2ConfigurationManagement::Salt::Group] Group specification
      # @return [Y2ConfigurationManagement::Widgets::Group]
      def build_group(group, locator)
        children = group.elements.map do |element_spec|
          build_element(element_spec, locator)
        end
        Y2ConfigurationManagement::Widgets::Group.new(group, children, locator)
      end

      # Builds a simple input element
      #
      # @todo To be extended with support for different elements
      #
      # @param input_spec [Hash] Group specification
      # @return [Y2ConfigurationManagement::Widgets::Text]
      def build_input(input_spec, locator)
        klass = INPUT_WIDGET_CLASS[input_spec.type]
        klass.new(input_spec, locator)
      end

      # Builds a collection
      #
      # @param collection_spec [Hash] Collection specification
      # @return [Y2ConfigurationManagement::Widgets::Collection]
      def build_collection(collection_spec, locator)
        Y2ConfigurationManagement::Widgets::Collection.new(collection_spec, controller, locator)
      end
    end
  end
end
