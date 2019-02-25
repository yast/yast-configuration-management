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

require "cwm"
require "y2configuration_management/salt/form_element_locator"

module Y2ConfigurationManagement
  module Widgets
    # Form widget to use when a form only contains a single input widget
    #
    # @example Scalar form
    #   form.value = "John Doe"
    #   form.store
    #   form.result #=> "John Doe"
    class SingleValueForm < ::CWM::CustomWidget
      # @return [CWM::AbstractWidget] Widget included in the form
      attr_reader :widget
      # @return [String] Form title
      attr_reader :title
      # @return [Object] Form value
      attr_accessor :value
      # @return [Hash] Form values from included widgets when this one is removed from the UI
      attr_reader :result

      # Constructor
      #
      # @param widget [CWM::AbstractWidget] Widget to include in the form
      # @param title  [String] Form title
      def initialize(widget, title: "")
        @widget = widget
        widget.parent = self
        @title = title
        super()
      end

      # This method propagates the value to the underlying widget.
      #
      # @see CWM::AbstractWidget#init
      def init
        widget.value = value.key?("$key") ? value : value["$value"]
      end

      def relative_locator
        Y2ConfigurationManagement::Salt::FormElementLocator.new([])
      end

      # Widget's content
      #
      # @see CWM::AbstractWidget
      def contents
        VBox(widget)
      end

      # Stores the widget's value
      #
      # The stored value can be obtained using the #result method even
      # after the widget has been removed from the UI.
      #
      # @see CWM::AbstractWidget
      def store
        @result = current_value
      end

      # Returns widget content
      #
      # @return [Hash] value of the widget
      def current_value
        widget.value.is_a?(Hash) ? widget.value : { "$value" => widget.value }
      end
    end
  end
end
