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

module Y2ConfigurationManagement
  module Salt
    # It builds new {FormElement}s depending on its specification type
    class FormElementFactory
      # Builds a new FormElement object based on the element specification and
      # maintaining a reference to its parent
      #
      # @param id [String]
      # @param spec [Hash]
      # @param parent [FormElement]
      def self.build(id, spec, parent:)
        class_for(spec["$type"]).new(id, spec, parent: parent)
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
  end
end
