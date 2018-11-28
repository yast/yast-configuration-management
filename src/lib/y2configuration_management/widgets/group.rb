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
  module Widgets
    # Represents a group of elements
    class Group < ::CWM::CustomWidget
      # @return [String] Widget name
      attr_reader :name
      # @return [String] Form element path
      attr_reader :path

      class << self
        # @param spec       [Y2ConfigurationManagement::Salt::FormElement] Element specification
        # @param children   [Array<AbstractWidget>] Widgets which are included in the group
        # @param controller [Y2ConfigurationManagement::Salt::FormController] Form controller
        def from_spec(spec, children, controller)
          new(spec.name, children, controller, spec.path)
        end
      end

      # Constructor
      #
      # @param name       [String] Widget name
      # @param children   [Array<AbstractWidget>] Widgets which are included in the group
      # @param controller [Y2ConfigurationManagement::Salt::FormController] Form controller
      # @param path       [String] Form element path
      def initialize(name, children, controller, path)
        textdomain "configuration_management"
        @name = name
        @children = children
        @controller = controller
        @path = path
        self.widget_id = "group:#{name}"
      end

      # Widget label
      #
      # @return [String]
      # @see CWM::AbstractWidget
      def label
        name
      end

      # Widget contents
      #
      # @return [Yast::Term]
      def contents
        VBox(*children)
      end

    private

      # @return [Array<CWM::AbstractWidget>] Widgets which are included in the group
      attr_reader :children
    end
  end
end
