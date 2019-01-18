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
    # which contains informaion about the open widget forms.  This data could have been stored
    # directly in the FormController instance, but it has been extracted in order to keep the
    # controller as simple as possible.
    class FormControllerState
      # Constructor
      def initialize
        @form_widgets = []
        @locators = []
        @actions = []
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
      def replace(new_action, new_locator)
        @actions[-1] = new_action
        @locators[-1] = new_locator
      end

      # Removes the information related to the most recently open form widget
      def close_form
        @form_widgets.pop
        @locators.pop
        @actions.pop
      end
    end
  end
end
