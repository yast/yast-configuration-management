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
      # @param spec [Y2ConfigurationManagement::Salt::FormInput] Element specification
      def initialize(spec)
        initialize_base(spec)
        @default = spec.default
        self.widget_id = "key_value:#{spec.id}"
        @value = nil
      end

      def init
        self.value = @value || default || {}
      end

      def contents
        VBox(
          key_widget,
          value_widget
        )
      end

      def value
        return {} if key_widget.value.nil?

        { "$key" => key_widget.value, "$value" => value_widget.value }
      end

      def value=(val)
        key_widget.value = (val || {}).dig("$key")
        value_widget.value = (val || {}).dig("$value")
        @value = value
      end

    private

      class Key < ::CWM::InputField
        def label
          "$key"
        end
      end

      class Value < ::CWM::InputField
        def label
          "$value"
        end
      end

      def key_widget
        @key ||= Key.new
      end

      def value_widget
        @key_value ||= Value.new
      end
    end
  end
end

