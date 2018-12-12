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

require "cwm"

module Y2ConfigurationManagement
  # This module contains the widgets which are used to display forms for Salt formulas
  module Widgets
    # This class represents a simple text field
    class Text < ::CWM::InputField
      # @return [String] Widget label
      attr_reader :label
      # @return [String] Default value
      attr_reader :default
      # @return [String] Form path
      attr_reader :path
      # @return [String] Form element id
      attr_reader :id

      # Constructor
      #
      # @param spec [Y2ConfigurationManagement::Salt::FormElement] Element specification
      # @param controller [FormController] Form controller
      def initialize(spec, controller)
        @label = spec.label
        @default = spec.default.to_s
        @controller = controller
        @path = spec.path
        @id = spec.id
        self.widget_id = "text:#{spec.id}"
      end

      # @see CWM::AbstractWidget
      def init
        self.value = default if value.nil? || value.empty?
      end

      # @see CWM::ValueBasedWidget
      def value=(val)
        super(val.to_s)
      end
    end
  end
end
