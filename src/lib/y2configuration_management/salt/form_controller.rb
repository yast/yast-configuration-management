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
      # @param form [Y2ConfigurationManagement::Salt::Form] Form
      # @param pillar [Y2ConfigurationManagement::Salt::Pillar] Pillar
      def initialize(form, pillar)
        @data = FormData.new(form, pillar.data)
        @form = form
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
      # @param path [String] Path to the element
      # @param index [Integer] Element's index when path refers to a collection
      def get(path, index = nil)
        @data.get(path, index)
      end

      # Opens a new dialog in order to add a new element to a collection
      #
      # @param path [String] Collection's path
      def add(path)
        result = edit_item(path, {})
        return if result.nil?
        @data.add_item(path, result.values.first)
        refresh_main_form
      end

      # Opens a new dialog in order to edit an element within a collection
      #
      # @param path  [String] Collection's path
      # @param index [Integer] Element's index
      def edit(path, index)
        result = edit_item(path, get(path, index))
        return if result.nil?
        @data.update_item(path, index, result.values.first)
        refresh_main_form
      end

      # Removes an element from a collection
      #
      # @param path  [String] Collection's path
      # @param index [Integer] Element's index
      def remove(path, index)
        @data.remove_item(path, index)
        refresh_main_form
      end

    private

      # @return [Form]
      attr_reader :form
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
        @main_form.value = get(form.root.path)
        @main_form
      end

      # Refreshes the main form content
      def refresh_main_form
        data.update(form.root.path, main_form.current_values)
        main_form.refresh(get(form.root.path))
      end

      # Displays a form to edit a given item
      #
      # @param path [String] Collection path
      # @param item [Object] Item to edit
      # @return [Hash,nil] edited data; `nil` when the user cancels the dialog
      def edit_item(path, item)
        element = form.find_element_by(path: path)
        widget_form = form_builder.build(element.prototype)
        widget_form.value = item
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
        return false unless Yast::Popup.YesNo("Do you want to exit?")
        main_form.store
        data.update(form.root.path, main_form.result)
        puts YAML.dump(data.to_h)
        true
      end
    end
  end
end
