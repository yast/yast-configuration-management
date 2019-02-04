# encoding: utf-8
#
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
require "y2configuration_management/widgets/base_mixin"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a key value field
    class KeyValue < ::CWM::CustomWidget
      include BaseMixin

      attr_reader :default

      # Constructor
      #
      # @param spec         [Salt::FormInput] Element specification
      # @param data_locator [Salt::FormElementLocator] Data locator (this locator include indexes
      #   in case of nested collections)
      def initialize(spec, data_locator)
        textdomain "configuration_management"

        initialize_base(spec, data_locator)
        @default = spec.default
        self.widget_id = "key_value:#{spec.id}"
        @value = nil
      end

      # @see CWM::AbstractWidget
      def init
        self.value = @value || default
      end

      # @see CWM::AbstractWidget
      def contents
        VBox(
          key_widget,
          value_widget
        )
      end

      # @see CWM::AbstractWidget
      # @return [Hash<String,String>]
      def value
        return {} if key_widget.value.to_s.empty?

        { "$key" => key_widget.value, "$value" => value_widget.value }
      end

      # @see CWM::AbstractWidget
      # @param val [Hash<String, String>]
      def value=(val)
        key_widget.value = (val || {}).dig("$key")
        value_widget.value = (val || {}).dig("$value")
        @value = val
      end

      # It returns false and report an error if the $key input is empty
      #
      # @see CWM::AbstractWidget
      # @return [Boolean] true if at least the $key input is not empty
      def validate
        if key_widget.value.to_s.empty?
          # TRANSLATORS: It reports that %s cannot be empty.
          Yast::Report.Error(_("%s: cannot be empty.") % label)
          return false
        end

        true
      end

    private

      # Input field for the key/value widget
      class KeyValueField < ::CWM::InputField
        attr_reader :label

        def initialize(id, label)
          @label = label
          self.widget_id = "key_value:#{id}"
          super()
        end
      end

      # Widget for the $key field
      #
      # @return [KeyValueField]
      def key_widget
        @key ||= KeyValueField.new("#{id}:key", label)
      end

      # Widget for the $value field
      #
      # @return [KeyValueField]
      def value_widget
        @key_value ||= KeyValueField.new("#{id}:value", _("Value"))
      end
    end
  end
end
