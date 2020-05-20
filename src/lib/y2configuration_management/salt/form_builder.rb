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
        number:    Y2ConfigurationManagement::Widgets::Number,
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
      # @param form       [Form] Form specification
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
        root_locator = form_element.is_a?(Container) ? locator : locator.parent
        if form_element.respond_to?(:elements)
          build_form(form_element, root_locator, controller)
        else
          build_single_value_form(form_element, root_locator)
        end
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

      # @param form_element [FormElement] Form element to include in the form
      # @param locator      [FormElementLocator] Form element locator
      # @return [Y2ConfigurationManagement::Widgets::Form]
      def build_single_value_form(form_element, locator)
        widget = build_element(form_element, locator)
        Y2ConfigurationManagement::Widgets::SingleValueForm.new(widget, title: form_element.name)
      end

      # @param form_element [FormElement] Root form element for the form
      # @param locator      [FormElementLocator] Form element locator
      # @param controller   [FormController] Controller to inject into the form
      # @return [Y2ConfigurationManagement::Widgets::Form]
      def build_form(form_element, locator, controller)
        tree_pager = build_tree_pager(form_element, locator)
        Y2ConfigurationManagement::Widgets::Form.new(
          tree_pager, controller, title: form_element.name
        )
      end

      # Builds a tree pager for a form
      #
      # The root element (Form#root) is excluded from the tree. However, when building
      # a pager for any other container, that container should be taken into account.
      # Additionally, the root element cannot contain simple input elements (usually it
      # contains just one container).
      #
      # See #build_root_tree_items and #build_container_tree_items for the details.
      #
      # @param form_element [FormElement] Form element
      # @param locator      [FormElementLocator] Form element locator
      def build_tree_pager(form_element, locator)
        tree_items =
          if form_element.parent.nil?
            build_root_tree_items(form_element)
          else
            build_container_tree_item(form_element, locator)
          end

        Widgets::TreePager.new(Array(tree_items))
      end

      # Builds tree pager items for the root element
      #
      # @param form_element [FormElement] Root form element
      # @return [Array<Widgets::PagerTreeItem>]
      def build_root_tree_items(form_element)
        form_element.elements.map { |e| build_tree_item(e, e.locator) }
      end

      # Builds tree pager item for a container
      #
      # @param form_element [FormElement] Form element
      # @param locator      [FormElementLocator] Form element locator
      # @return [Widgets::PagerTreeItem]
      def build_container_tree_item(form_element, locator)
        build_tree_item(form_element, locator).tap { |t| t.main = true }
      end

      # Builds a tree item for a given form element
      #
      # @param form_element [FormElement] Form element
      # @param locator      [FormElementLocator] Form element locator
      # @return [Widgets::PagerTreeItem]
      def build_tree_item(form_element, locator)
        if form_element.respond_to?(:elements)
          same_page, other_page = form_element.elements.partition { |e| shared_page?(e) }
        else
          same_page = [form_element]
          other_page = []
        end

        widgets = same_page.map { |e| build_element(e, locator) }
        children = other_page.map { |e| build_tree_item(e, locator.join(e.id.to_sym)) }

        page = Widgets::Page.new(locator.last.to_s, form_element.name, widgets)
        Widgets::PagerTreeItem.new(page, children: children)
      end

      # Determines whether a form element should be placed in a different page or share one
      #
      # Only {FormInput} instances are placed in the same page.
      #
      # @param form_element [FormElement] Form element to check
      # @return [Boolean]
      def shared_page?(form_element)
        form_element.is_a?(FormInput)
      end
    end
  end
end
