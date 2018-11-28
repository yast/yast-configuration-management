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
    # https://github.com/SUSE/spacewalk/wiki/Writing-Salt-Formulas-for-SUSE-Manager
    class FormBuilder
      # Build the form
      #
      # @param form_spec  [Y2ConfigurationManagement::Salt::Form] Form specification
      # @param controller [Y2ConfigurationManagement::Salt::FormController] Form controller
      # @return [Array<Y2ConfigurationManagement::Widgets::Form>]
      def build(form_spec, controller = nil)
        form_spec.elements.map do |element_spec|
          build_element(element_spec, controller)
        end
      end

    private

      # Build a form element
      #
      # The form element can be a simple input control, a group or even a collection.
      # The type is determined by the `$type` key which should be included in the element
      # specification.
      #
      # @param element_spec [Hash]
      # @return [Y2ConfigurationManagement::Widgets::Group,
      #          Y2ConfigurationManagement::Widgets::Text,
      #          Y2ConfigurationManagement::Widgets::Collection]
      def build_element(element_spec, controller)
        if [:group, :namespace].include?(element_spec.type)
          build_group(element_spec, controller)
        elsif element_spec.type == :"edit-group"
          build_collection(element_spec, controller)
        else
          build_input(element_spec, controller)
        end
      end

      # Build a form group
      #
      # @param group_spec [Hash] Group specification
      # @param controller [Controller]
      # @return [Y2ConfigurationManagement::Widgets::Group]
      def build_group(group_spec, controller)
        children = group_spec.elements.map do |element_spec|
          build_element(element_spec, controller)
        end
        Y2ConfigurationManagement::Widgets::Group.from_spec(group_spec, children, controller)
      end

      # Builds a simple input element
      #
      # @todo To be extended with support for different elements
      #
      # @param input_spec [Hash] Group specification
      # @return [Y2ConfigurationManagement::Widgets::Text]
      def build_input(input_spec, controller)
        klass =
          case input_spec.type
          when :text, :email, :number
            Y2ConfigurationManagement::Widgets::Text
          when :select
            Y2ConfigurationManagement::Widgets::Select
          end
        klass.from_spec(input_spec, controller)
      end

      # Builds a collection
      #
      # @param collection_spec [Hash] Collection specification
      # @return [Y2ConfigurationManagement::Widgets::Collection]
      def build_collection(collection_spec, controller)
        Y2ConfigurationManagement::Widgets::Collection.from_spec(collection_spec, controller)
      end
    end
  end
end
