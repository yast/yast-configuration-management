# encoding: utf-8

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

module Y2ConfigurationManagement
  module Salt
    # Stores the UI state information
    #
    # This class holds information related to FormController. Basically, it behaves like a stack
    # which contains informaion about the open widget forms and the current form data. Those items
    # could have been stored directly in the FormController instance, but they have been extracted
    # in order to keep the controller as simple as possible.
    class FormControllerState
      # Constructor
      #
      # @param data [FormData] Initial form data
      def initialize(data)
        @form_widgets = []
        @locators = []
        @actions = []
        @form_data_instances = [data]
      end

      # Registers that a new form has been open
      #
      # It stores relevant information (the action, the locator and the form).
      #
      # @param action      [Symbol] Action which triggered the form (:add or :edit)
      # @param locator     [FormElementLocator] Form element locator
      # @param form_widget [Widgets::Form] Form widget
      def open_form(action, locator, form_widget)
        @form_widgets << form_widget
        @locators << locator
        @actions << action
        backup_data
      end

      # Most recently open form widget
      #
      # @return [Widgets::Form] Form widget
      def form_widget
        @form_widgets.last
      end

      # Current action
      #
      # @return [Symbol] :add or :edit
      def action
        @actions.last
      end

      # Locator of the current form widget
      #
      # @return [FormElementLocator]
      def locator
        @locators.last
      end

      # Replaces the current action/locator
      #
      # @param new_action  [Symbol]
      # @param new_locator [FormElementLocator]
      def replace(new_action, new_locator)
        @actions[-1] = new_action
        @locators[-1] = new_locator
      end

      # Removes the information related to the most recently open form widget
      def close_form(rollback: false)
        @form_widgets.pop
        @locators.pop
        @actions.pop
        if rollback
          restore_backup
        else
          remove_backup
        end
      end

      # Current form data
      #
      # @return [FormData]
      def form_data
        @form_data_instances.last
      end

    private

      # Performs a backup of the current form data
      def backup_data
        @form_data_instances << form_data.copy
      end

      # Restores the last backup of the current form data by removing the current snapshot
      def restore_backup
        @form_data_instances.pop
      end

      # Clears the last backup if it exists
      def remove_backup
        @form_data_instances.delete_at(-2)
      end
    end
  end
end
