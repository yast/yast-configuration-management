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
require "time"
require "y2configuration_management/widgets/base_mixin"

module Y2ConfigurationManagement
  module Widgets
    # This class represents a datetime field
    class DateTime < ::CWM::CustomWidget
      include BaseMixin

      attr_reader :default

      # Constructor
      #
      # @param spec [Y2ConfigurationManagement::Salt::FormInput] Element specification
      def initialize(spec)
        initialize_base(spec)
        @default = spec.default.to_s
        self.widget_id = "datetime:#{spec.id}"
        @value = nil
      end

      def contents
        VBox(
          HBox(
            date,
            HSpacing(1),
            VBox(
              Yast::UI.TextMode ? VSpacing(1) : Label(" "),
              time
            )
          )
        )
      end

      def init
        self.value = @value || default
      end

      def value
        "#{date.value} #{time.value}"
      end

      def value=(val)
        t = val.to_s.empty? ? ::Time.new : ::Time.parse(val)
        date.value = t.strftime("%Y-%m-%d")
        time.value = t.strftime("%H:%M:%S")
        @value = value
      end

      def store
        @value = value
      end

    private

      # Date field widget
      class Date < ::CWM::DateField
        def initialize(label)
          @label = label
        end

        def opt
          [:notify]
        end

        attr_reader :label
      end

      # Time field widget
      class Time < ::CWM::TimeField
        def label
          ""
        end
      end

      def date
        @date ||= Date.new(label)
      end

      def time
        @time ||= Time.new
      end
    end
  end
end
