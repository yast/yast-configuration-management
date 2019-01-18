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
require "y2configuration_management/salt/form_controller_state"
require "yaml"

Yast.import "CWM"
Yast.import "Wizard"

module Y2ConfigurationManagement
  module Salt
    # This class takes care of driving the forms for a Salt Formula.
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
      include Yast::Logger
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
        @state = FormControllerState.new
      end

      # Renders the main form's dialog
      def show_main_dialog
        form_widget = form_builder.build(form.root)
        form_widget.value = get(form.root.locator)
        state.open_form(:edit, form.root.locator, form_widget)
        Yast::Wizard.CreateDialog
        ret = Yast::CWM.show(
          HBox(form_widget),
          caption: form.root.name, next_handler: method(:next_handler)
        )
        state.close_form
        ret
      ensure
        Yast::Wizard.CloseDialog
      end

      # Convenience method for returning the value of a given element
      #
      # @param locator [String] Locator of the element
      def get(locator)
        @data.get(locator)
      end

      # Opens a new dialog in order to add a new element to a collection
      #
      # @param relative_locator [FormElementLocator] Collection's locator
      def add(relative_locator)
        add_or_edit_item(:add, relative_locator)
      end

      # Opens a new dialog in order to edit an element within a collection
      #
      # @param relative_locator [FormElementLocator] Elements's locator
      def edit(relative_locator)
        add_or_edit_item(:edit, relative_locator)
      end

      # Removes an element from a collection
      #
      # @param relative_locator [FormElementLocator] Elements's locator
      def remove(relative_locator)
        locator = state.locator.join(relative_locator)
        @data.remove_item(locator)
        refresh_top_form
      end

      def update_visibility
        state.form_widget.store
        data.update(form.root.locator, state.form_widget.result)
        state.form_widget.update_visibility(data)
      end

    private

      # @return [Form]
      attr_reader :form

      # @return [Pillar]
      attr_reader :pillar

      # @return [FormData]
      attr_reader :data

      # @return [State]
      attr_reader :state

      # Returns the form builder
      #
      # @return [Y2ConfigurationManagement::Salt::FormBuilder]
      def form_builder
        @form_builder ||= Y2ConfigurationManagement::Salt::FormBuilder.new(self)
      end

      # Refreshes the most recently open form widget
      def refresh_top_form
        state.form_widget.refresh(get(state.locator))
        state.form_widget.update_visibility(data)
      end

      # Displays a popup
      #
      # @param title    [String] Popup title
      # @param widget [Array<CWM::AbstractWidget>] Popup content (as an array of CWM widgets)
      # @return [Hash,nil] Dialog's result
      def show_popup(widget)
        Widgets::FormPopup.new(widget.title, widget).run
        widget.result
      end

      # @todo This version is just for debugging purposes. It should be replaced with a meaningful
      #   version.
      def next_handler
        state.form_widget.store
        data.update(form.root.locator, state.form_widget.result)
        pillar.data = data.to_h.fetch("root", {})
        puts pillar.dump
        true
      end

      # Displays a form to add/edit a given item and updates the form data
      #
      # When the locator refers to a collection, it assumes that the
      # item should be added.
      #
      # @param action           [Symbol] :add or :edit
      # @param relative_locator [FormElementLocator] Collection locator relative to the popup
      # @return [Hash,nil] edited data; `nil` when the user cancels the dialog
      def add_or_edit_item(action, relative_locator)
        add_or_update_parent
        result = run_popup(action, relative_locator)
        update_form_data(result)
        state.close_form
        refresh_top_form
      end

      # Displays the add/edit form and returns the user's input
      #
      # @param action           [Symbol] :add or :edit
      # @param relative_locator [FormElementLocator] Collection locator relative to the popup
      # @return [Hash, nil] User's input or nil if the user pushed canceled the dialog
      def run_popup(action, relative_locator)
        abs_locator = state.locator.join(relative_locator)
        form_widget = item_form_for(abs_locator)
        form_widget.value = get(abs_locator) if action == :edit
        state.open_form(action, abs_locator, form_widget)
        show_popup(form_widget)
      end

      # Updates the form data depending on the action
      #
      # @param result [Hash,nil] Result to process
      def update_form_data(result)
        return if result.nil?
        if state.action == :add
          @data.add_item(state.locator, result)
        else
          @data.update(state.locator, result)
        end
      end

      # Adds or updates the parent of a collection item
      #
      # When trying to add an element to a collection, it is necessary that the parent
      # object exists.
      def add_or_update_parent
        state.form_widget.store
        parent = state.form_widget.result

        if state.action == :edit
          @data.update(state.locator, parent)
        else
          @data.add_item(state.locator, parent)
          locator = state.locator.join(get(state.locator).size - 1)
          state.replace(:edit, locator)
        end
      end

      # Builds a form widget for a given locator
      #
      # @param locator [FormElementLocator] Form element to represent
      # @return [Y2ConfigurationManagement::Widgets::Form] Form widget
      def item_form_for(locator)
        element = form.find_element_by(locator: locator.unbounded)
        form_widget = form_builder.build(element.prototype)
        form_widget.title = element.name
        form_widget
      end
    end
  end
end
