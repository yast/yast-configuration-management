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
require "yaml"

Yast.import "CWM"
Yast.import "Wizard"

module Y2ConfigurationManagement
  module Salt
    # This class takes care of driving the form for a Salt Formula.
    #
    # The constructor of this class takes a ({Y2ConfigurationManagement::Salt::Form a form
    # description}) which will be used to build the UI when the #show_main_dialog method
    # is called.
    #
    # The data is stored using a {Y2ConfigurationManagement::Salt::FormData} instance and the values
    # are injected into the UI as a Hash using the {Y2ConfigurationManagement::Widgets::Form#value=}
    # method.
    #
    # Finally, all widgets has access to the controller instance if needed. For instance, the
    # Y2ConfigurationManagement::Widgets::Collection reacts to the buttons being pushed by calling
    # back some controller methods (basically {#add}, {#edit} or {#remove}).
    #
    # @example Rendering the form
    #   formula_form = Form.from_file("test/fixtures/form.yml")
    #   formula_pillar = Pillar.from_file("test/fixtures/pillar/pillar.sls")
    #   controller = FormController.new(formula_form, formula_pillar)
    #   controller.show_main_dialog
    class FormController
      include Yast::I18n
      include Yast::UIShortcuts

      # Constructor
      #
      # @param form [Y2ConfigurationManagement::Salt::Form]
      # @param pillar [Y2ConfigurationManagement::Salt::Pillar]
      def initialize(form, pillar)
        @data = FormData.new(form, pillar)
        @form = form
        @pillar = pillar
      end

      # Renders the main form's dialog
      def show_main_dialog
        Yast::Wizard.CreateDialog
        Yast::CWM.show(
          HBox(main_form),
          caption: form.root.name, next_handler: method(:next_handler)
        )
      ensure
        Yast::Wizard.CloseDialog
      end

      # Convenience method for returning the value of a given element
      #
      # @param locator [String] Locator of the element
      # @param index [Integer] Element's index when locator refers to a collection
      def get(locator, index = nil)
        @data.get(locator, index)
      end

      # Opens a new dialog in order to add a new element to a collection
      #
      # @param locator [String] Collection's locator
      def add(locator)
        result = edit_item(locator, nil)
        return if result.nil?
        @data.add_item(locator, result.values.first)
        refresh_main_form
      end

      # Opens a new dialog in order to edit an element within a collection
      #
      # @param locator  [String] Collection's locator
      # @param index [Integer] Element's index
      def edit(locator, index)
        result = edit_item(locator, get(locator, index))
        return if result.nil?
        @data.update_item(locator, index, result.values.first)
        refresh_main_form
      end

      # Removes an element from a collection
      #
      # @param locator  [String] Collection's locator
      # @param index [Integer] Element's index
      def remove(locator, index)
        @data.remove_item(locator, index)
        refresh_main_form
      end

    private

      # @return [Form]
      attr_reader :form

      # @return [Pillar]
      attr_reader :pillar

      # @return [FormData]
      attr_reader :data

      # Returns the form builder
      #
      # @return [Y2ConfigurationManagement::Salt::FormBuilder]
      def form_builder
        @form_builder ||= Y2ConfigurationManagement::Salt::FormBuilder.new(self)
      end

      # Renders the main form's dialog
      def main_form
        return @main_form if @main_form
        @main_form = form_builder.build(form.root.elements)
        @main_form.value = get(form.root.locator)
        @main_form
      end

      # Refreshes the main form content
      def refresh_main_form
        data.update(form.root.locator, main_form.current_values)
        main_form.refresh(get(form.root.locator))
      end

      # Displays a form to edit a given item
      #
      # @param locator [String] Collection locator
      # @param item [Object] Item to edit
      # @return [Hash,nil] edited data; `nil` when the user cancels the dialog
      def edit_item(locator, item)
        element = form.find_element_by(locator: locator)
        widget_form = form_builder.build(element.prototype)
        wid = locator[1..-1].split(".").last
        widget_form.value = { wid => item }
        show_popup(element.name, widget_form)
      end

      # Displays a popup
      #
      # @param title    [String] Popup title
      # @param widget [Array<CWM::AbstractWidget>] Popup content (as an array of CWM widgets)
      # @return [Hash,nil] Dialog's result
      def show_popup(title, widget)
        Widgets::FormPopup.new(title, widget).run
        widget.result
      end

      # @todo This version is just for debugging purposes. It should be replaced with a meaningful
      #   version.
      def next_handler
        main_form.store
        data.update(form.root.locator, main_form.result)
        pillar.data = data.to_h.fetch("root", {})
        puts pillar.dump
        true
      end
    end
  end
end
