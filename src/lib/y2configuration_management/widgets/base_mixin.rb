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

module Y2ConfigurationManagement
  module Widgets
    # A widget has two ancestry lines: CWM, and Salt Forms.
    # CWM is expressed through inheritance (class Boolean < ::CWM::CheckBox),
    # Salt Forms through module inclusion (class Boolean; include BaseMixin; end).
    module BaseMixin
      # @return [String] Form element id
      attr_reader :id
      # @return [String] Form locator
      attr_reader :locator
      # @return [String] Widget label
      attr_reader :label
      # @return [Array<CWM::AbstractWidget>] Parent widget
      attr_accessor :parent

      # @param spec         [Salt::FormElement] Element specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize_base(spec, data_locator)
        @id = spec.id
        @locator = data_locator
        @label = spec.label
      end

      # Locator relative to the form where the widget belongs
      #
      # @return [FormElementLocator] Form element locator
      def relative_locator
        return parent.relative_locator.join(id.to_sym) if respond_to?(:parent) && parent
        Y2ConfigurationManagement::Salt::FormElementLocator.new([])
      end
    end
  end
end
