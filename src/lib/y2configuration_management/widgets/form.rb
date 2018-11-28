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

 module Yast
   module ConfigurationManagement
     # This module contains the widgets which are used to display forms for Salt formulas
     module Widgets
       # Represents a collection of elements
       class Collection < ::CWM::CustomWidget
         attr_reader :name, :min_items, :max_items, :controller, :path

         class << self
           def from_spec(spec, controller)
             new(spec.name, spec.min_items, spec.max_items, controller, spec.path)
           end
         end

         # Constructor
         #
         # @param name       [String] Widget name
         # @param min_items  [Integer] Min qty of items
         # @param max_items  [Integer] Max qty of items
         # @param controller [FormController] Form controller
         def initialize(name, min_items, max_items, controller, path)
           textdomain "configuration_management"
           @name = name
           @min_items = min_items
           @max_items = max_items
           @controller = controller
           @path = path # form element path
           self.widget_id = "collection:#{name}"
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
         # @return [Term]
         def contents
           VBox(
             Table(
               Id("table_#{name}"),
               Opt(:notify, :immediate),
               Header("name"),
               []
             ),
             HBox(
               HStretch(),
               PushButton(Id(:add), Yast::Label.AddButton),
               PushButton(Id(:edit), Yast::Label.EditButton),
               PushButton(Id(:remove), Yast::Label.RemoveButton)
             )
           )
         end

         # Forces the widget to inspect all events
         #
         # @return [TrueClass]
         def handle_all_events
           true
         end

         # Events handler
         #
         # @param event [Hash] Event specification
         def handle(event)
           case event["ID"]
           when :add
             controller.add(path)
           when :edit
             controller.edit(path, selected_row) if selected_row
           when :remove
             controller.remove(path, selected_row) if selected_row
           end
           nil
         end

         def selected_row
           row_id = UI.QueryWidget(Id("table_#{name}"), :CurrentItem)
           row_id ? row_id.to_i : nil
         end
       end
     end
   end
 end
