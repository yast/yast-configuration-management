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
    # which contains information about the open widget forms and the current form data. Those items
    # could have been stored directly in the FormController instance, but they have been extracted
    # in order to keep the controller as simple as possible.
    class FormControllerState
      # Constructor
      #
      # @param data [FormData] Initial form data
      def initialize(data)
        @form_widgets = []
        @locators = []
        @form_data_snapshots = [data]
      end

      # Registers that a new form has been open
      #
      # It stores relevant information (the current locator and the form).
      #
      # @param locator     [FormElementLocator] Form element locator
      # @param form_widget [Widgets::Form] Form widget
      def open_form(locator, form_widget)
        @form_widgets << form_widget
        @locators << locator
        backup_data
      end

      # Most recently open form widget
      #
      # @return [Widgets::Form] Form widget
      def form_widget
        @form_widgets.last
      end

      # Locator of the current form widget
      #
      # @return [FormElementLocator]
      def locator
        @locators.last
      end

      # Removes the information related to the most recently open form widget
      def close_form(rollback: false)
        @form_widgets.pop
        @locators.pop
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
        @form_data_snapshots.last
      end

    private

      # Performs a backup of the current form data
      def backup_data
        @form_data_snapshots << form_data.copy
      end

      # Restores the last backup of the current form data by removing the current snapshot
      def restore_backup
        @form_data_snapshots.pop
      end

      # @return [Integer] Position of the previous backup
      PREVIOUS_SNAPSHOT_POSITION = -2

      # Clears the last backup if it exists
      def remove_backup
        # This is another way of saying `top = @fdi.pop; @fdi.last = top`,
        # or "shorten the snapshot stack but commit the last element"
        @form_data_snapshots.delete_at(PREVIOUS_SNAPSHOT_POSITION)
      end
    end
  end
end
