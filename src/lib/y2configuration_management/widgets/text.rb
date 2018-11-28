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
      class << self
        # Builds a widget from a FormElement specification.
        #
        # @param spec [Y2ConfigurationManagement::Salt::FormElement] Element specification
        # @return [Text] New text widget
        def from_spec(spec, controller)
          new(spec.name, spec.default, controller, spec.path)
        end
      end

      # @return [String] Widget name
      attr_reader :name
      # @return [String] Default value
      attr_reader :default
      # @return [String] Form path
      attr_reader :path

      # Constructor
      #
      # @param name       [String] Widget name
      # @param default    [String,nil] Default value
      # @param controller [FormController] Form controller
      # @param path       [String] Form path
      def initialize(name, default, controller, path)
        @name = name
        @default = default.to_s
        @controller = controller
        @path = path
        self.widget_id = "text:#{name}"
      end

      # Widget label
      #
      # @return [String]
      # @see CWM::AbstractWidget
      def label
        widget_id.to_s
      end

      # @see CWM::AbstractWidget
      def init
        self.value = default
      end
    end
  end
end
