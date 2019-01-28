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

require "yast"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/form_element_helpers"

module Y2ConfigurationManagement
  module Salt
    # It builds new {FormElement}s depending on its specification type
    class FormElementFactory
      include FormElementHelpers

      class << self
        # Builds a new FormElement object based on the element specification
        #
        # This is a convenience method which relies on {FormElementFactory#build}.
        #
        # @see FormElementFactory#build
        def build(id, spec, parent: nil)
          new.build(id, spec, parent: parent)
        end
      end

      # Builds a new FormElement object based on the element specification and
      # maintaining a reference to its parent
      #
      # @param id [String]
      # @param spec [Hash]
      # @param parent [FormElement]
      def build(id, spec, parent: nil)
        type = type_for(spec)
        class_for(type).new(id, spec, parent: parent)
      end

    private

      # @param type [String]
      # @return [FormElement]
      def class_for(type)
        case type
        when "namespace", "hidden-group", "group"
          Container
        when "edit-group"
          Collection
        else
          FormInput
        end
      end

      # Returns the type for a given form element specification
      #
      # When no type is specified, it tries to infer the right one.
      #
      # @param spec [Hash] Form element specification
      # @return [String] Form element type
      def type_for(spec)
        return spec["$type"] if spec.key?("$type")
        form_elements_in(spec).size > 1 ? "group" : "text"
      end
    end
  end
end
