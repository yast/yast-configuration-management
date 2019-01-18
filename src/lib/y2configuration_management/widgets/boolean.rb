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
    # This class represents a boolean (checkbox) field. TODO: is tristate possible?
    class Boolean < ::CWM::ReplacePoint
      include BaseMixin

      # @return [Boolean] Default value
      attr_reader :default

      extend Forwardable
      def_delegators :@inner, :value, :value=

      include InvisibilityCloak

      # A helper to go inside a ReplacePoint
      class CheckBox < ::CWM::CheckBox
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
        @default = spec.default == true # nil -> false

        @inner = CheckBox.new(id: "boolean:#{spec.id}", label: spec.label)
        super(id: "vis:#{spec.id}", widget: @inner)
        initialize_invisibility_cloak(spec.visible_if)
      end

      # @see CWM::AbstractWidget
      def init
        replace(@inner)
        self.value = default
      end

      # Fixup for CWM::ReplacePoint which defaults to non unique ids
      # @return [UITerm]
      def contents
        # In `contents` we must use an Empty Term, otherwise CWMClass
        # would see an {AbstractWidget} and handle events itself,
        # which result in double calling of methods like {handle} or {store} for
        # initial widget.
        ReplacePoint(Id(widget_id), Empty(Id("empty:#{widget_id}")))
      end
    end
  end
end
