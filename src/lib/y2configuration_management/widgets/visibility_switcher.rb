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

module Y2ConfigurationManagement
  module Widgets
    # Widgets that can become invisible via the {visible=} method.
    # TODO: the value is discarded; check how it feels, maybe we want to save/restore it.
    class VisibilitySwitcher < ::CWM::ReplacePoint
      EMPTY_WIDGET = CWM::Empty.new("ic_empty")

      # @return [Boolean]
      attr_reader :visible

      # @return [CWM::AbstractWidget] The wrapped widget
      attr_reader :inner

      def initialize(id:, widget:)
        self.widget_id = id
        @inner = widget
        @visible = true

        # Allow #value= before #init.
        # Wrap the :value accessor to add an "uninitialized" state
        # (which the YUI/CWM widget does not have)
        # so that we can give it a default
        # It also remembers the last widget value
        # in case we are hiding it and showing again
        @value = nil
      end

      # Show or hide the widget, make it visible/invisible
      # @param visible [Boolean]
      def visible=(visible)
        return if @visible == visible
        if visible
          replace(@inner)
          @visible = visible
          # restore the previous value
          self.value = @value
        else
          # save the last value
          @value = value
          @visible = visible
          replace(EMPTY_WIDGET)
        end
      end

      def value
        return nil unless @visible
        @value = @inner.value
      end

      def value=(value)
        return unless @visible
        @value = value
        @inner.value = value
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

      # Initialize the widget
      def init
        if @visible
          replace(@inner)
          self.value = @value
        else
          replace(EMPTY_WIDGET)
        end
      end

      def replace(widget)
        return unless Yast::UI.WidgetExists(Id(widget_id))
        super(widget)
      end
    end
  end
end
