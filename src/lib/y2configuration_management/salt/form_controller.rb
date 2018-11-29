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
require "y2configuration_management/widgets/form_popup"

Yast.import "CWM"
Yast.import "Wizard"

module Y2ConfigurationManagement
  module Salt
    # This class takes care of driving the form for a Salt Formula.
    #
    # @example Rendering a form
    #   form_spec = Form.from_file("test/fixtures/form.yml")
    #   controller = FormController.new(form_spec)
    #   controller.show_main_dialog
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

      # Renders the main form's dialog
      def show_main_dialog
        element = spec.root
        show_dialog(element.name, form_builder.build(element, self))
      end

      # Opens a new dialog in order to add a new element to a collection
      # @todo
      def add(path)
        element = spec.find_element_by(path: path).prototype
        show_popup(element.name, form_builder.build(element, self))
      end

      # Opens a new dialog in order to edit a new element in a collection
      # @todo
      def edit(_path, index)
        log.info "Editing element #{index}"
      end

      # Removes an element from a collection
      # @todo
      def remove(_path, index)
        log.info "Removing element #{index}"
      end

    private

      attr_reader :spec, :state

      def form_builder
        # TODO: the FormBuilder could receive the controller in the constructor
        @form_builder ||= Y2ConfigurationManagement::Salt::FormBuilder.new
      end

      # Displays a form dialog
      #
      # @param title    [String] Popup title
      # @param contents [Array<CWM::AbstractWidget>] Popup content (as an array of CWM widgets)
      def show_dialog(title, contents)
        next_handler = proc { Yast::Popup.YesNo("Exit?") }
        Yast::Wizard.CreateDialog
        Yast::CWM.show(
          VBox(*contents), caption: title, next_handler: next_handler
        )
        Yast::Wizard.CloseDialog
      end

      # Displays a popup
      #
      # @param title    [String] Popup title
      # @param contents [Array<CWM::AbstractWidget>] Popup content (as an array of CWM widgets)
      def show_popup(title, contents)
        Widgets::FormPopup.new(title, contents).run
      end
    end
  end
end
