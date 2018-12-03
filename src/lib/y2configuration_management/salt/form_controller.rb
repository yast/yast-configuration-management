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
require "y2configuration_management/salt/form_data"
require "y2configuration_management/widgets/form_popup"

Yast.import "CWM"
Yast.import "Wizard"

module Y2ConfigurationManagement
  module Salt
    # This class takes care of driving the form for a Salt Formula.
    #
    # @example Rendering a form
    #   form_form = Form.from_file("test/fixtures/form.yml")
    #   controller = FormController.new(form_form)
    #   controller.show_main_dialog
    class FormController
      include Yast::I18n
      include Yast::UIShortcuts

      # Constructor
      #
      # @param form [Y2ConfigurationManagement::Salt::Form] Form

      def initialize(form)
        @data = FormData.new(form)
        @form = form
      end

      # Renders the main form's dialog
      def show_main_dialog
        Yast::Wizard.CreateDialog
        Yast::CWM.show(
          HBox(replace_point),
          caption: form.root.name, next_handler: method(:next_handler)
        )
        Yast::Wizard.CloseDialog
      end

      def get(path)
        @data.get(path)
      end

      # Opens a new dialog in order to add a new element to a collection
      #
      # @param path [String] Collection's path
      def add(path)
        element = form.find_element_by(path: path).prototype
        widget_form = form_builder.build(element)
        result = show_popup(element.name, form_builder.build(element))
        return if result.nil?
        @data.add(path, result.values.first)
        refresh_main_form
      end

      # Removes an element from a collection
      #
      # @param path  [String] Collection's path
      # @param index [Integer] Element's index
      def remove(path, index)
        @data.remove(path, index)
        refresh_main_form
      end

    private

      attr_reader :form, :data

      # Returns the form builder
      #
      # @return [Y2ConfigurationManagement::Salt::FormBuilder]
      def form_builder
        @form_builder ||= Y2ConfigurationManagement::Salt::FormBuilder.new(self)
      end

      # Displays a form dialog
      #
      # @param title       [String] Dialog title
      # @param widget_form [Y2ConfigurationManagement::Widgets:Form] Form to show
      def show_dialog(widget_form)
        Yast::CWM.show(
          HBox(replace_point),
          caption: form.root.name, next_handler: method(:next_handler)
        )
      end

      # Renders the main form's dialog
      def main_form
        widget_form = form_builder.build(form.root.elements)
        widget_form.value = get(form.root.path)
        widget_form
      end

      # Refreshes the main form content
      def refresh_main_form
        replace_point.replace(main_form)
      end

      # Replace point to place the main dialog
      #
      # @return [CWM::ReplacePoint]
      def replace_point
        @replace_point ||= ::CWM::ReplacePoint.new(widget: main_form)
      end

      # Displays a popup
      #
      # @param title    [String] Popup title
      # @param contents [Array<CWM::AbstractWidget>] Popup content (as an array of CWM widgets)
      # @return [Hash,nil] Dialog's result
      def show_popup(title, widget)
        Widgets::FormPopup.new(title, widget).run
        widget.result
      end

      # @todo This version is just for debugging purposes. It should be replaced with a meaningful
      #   version.
      def next_handler
        return false unless Yast::Popup.YesNo("Do you want to exit?")
        puts data.to_h.inspect
        true
      end
    end
  end
end
