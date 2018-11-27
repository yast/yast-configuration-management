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

require "y2configuration_management/salt/form_builder"

Yast.import "CWM"
Yast.import "Wizard"

module Y2ConfigurationManagement
  module Salt
    # This class takes care of driving the form for a Salt Formula.
    #
    # @example Rendering a form
    #   form_spec = Form.from_file("test/fixtures/form.yml")
    #   controller = FormController.new(form_spec)
    #   controller.render
    #
    # @example Rendering a subform
    #   controller.render("dhcp.ranges")
    class FormController
      include Yast::I18n
      include Yast::UIShortcuts

      # Constructor
      #
      # @param spec [Y2ConfigurationManagement::Salt::Form] Form specification
      # @param state [Hash] Current state (TODO)
      def initialize(spec, state = {})
        @state = state # TODO
        @spec = spec
      end

      # Renders a form
      #
      # @param path [String] Path to the root element to show
      def render(path = nil)
        element = path ? spec.find_element_by(path: path) : spec.root
        show_dialog(form_builder.build(element, self))
      end

      # Opens a new dialog in order to add a new element to a collection
      def add(path)
        element = spec.find_element_by(path: path).prototype
        show_dialog(form_builder.build(element, self), create_dialog: false)
      end

      # Opens a new dialog in order to edit a new element in a collection
      def edit(path, index)
        log.info "Editing element #{index}"
      end

      # Removes an element from a collection
      def remove(path, index)
        log.info "Removing element #{index}"
      end

    private

      attr_reader :spec, :state

      def form_builder
        # TODO: the FormBuilder could receive the controller in the constructor
        @form_builder ||= Y2ConfigurationManagement::Salt::FormBuilder.new
      end

      def show_dialog(contents, create_dialog: true)
        next_handler = proc { Yast::Popup.YesNo("Exit?") }
        Yast::Wizard.CreateDialog if create_dialog
        Yast::CWM.show(
          HBox(*contents), caption: _("Test formula"), next_handler: next_handler
        )
        Yast::Wizard.CloseDialog if create_dialog
      end
    end
  end
end
