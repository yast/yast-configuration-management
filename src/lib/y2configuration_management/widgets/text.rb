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
require "y2configuration_management/widgets/base_mixin"

module Y2ConfigurationManagement
  # This module contains the widgets which are used to display forms for Salt formulas
  module Widgets
    # This class represents a simple text field
    class Text < CWM::ReplacePoint
      # @return [String] Default value
      attr_reader :default

      include BaseMixin

      extend Forwardable
      def_delegators :@inner, :value, :value=

      include InvisibilityCloak

      # A helper to go inside a ReplacePoint
      class InputField < ::CWM::InputField
        # @return [String] Widget label
        attr_reader :label

        def initialize(id:, label:)
          self.widget_id = id
          @label = label
        end

        # TODO: only if I am mentioned in a visible_if
        def opt
          [:notify]
        end
      end

      # Constructor
      #
      # @param spec [Y2ConfigurationManagement::Salt::FormElement] Element specification
      def initialize(spec)
        initialize_base(spec)
        @default = spec.default.to_s

        @inner = InputField.new(id: "text:#{spec.id}", label: spec.label)
        super(id: "vis:#{spec.id}", widget: @inner)
        initialize_invisibility_cloak(spec.visible_if)
      end

      # @return [UITerm]
      def contents
        # CWM::ReplacePoint has ReplacePoint(..., Empty) to prevent
        # alleged double calls of handlers.
        # But that means a Form#init will be setting values to widgets
        # that are not there :-/
        # So let's include the wrapped widget from the start
        ReplacePoint(Id(widget_id), @inner)
      end

      # @see CWM::AbstractWidget
      def init
        saved_value = value
        replace(@inner)
        self.value = if saved_value.nil? || saved_value.empty?
          default
        else
          saved_value
        end
      end

      # @see CWM::ValueBasedWidget
      def value=(val)
        # FIXME: clashes with forwarding to @inner
        # super(val.to_s)
        @inner.value = val.to_s
      end
    end
  end
end
