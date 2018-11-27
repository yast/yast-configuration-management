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
       # This class represents a simple text field
       class Text < ::CWM::InputField
         class << self
           # Builds a widget from a FormElement specification.
           #
           # @param spec [Y2ConfigurationManagement::Salt::FormElement] Element specification
           # @return [Text] New text widget
           def from_spec(spec, controller)
             new(spec.name, controller, spec.path)
           end
         end

         # @return [String] Widget name
         attr_reader :name

         # Constructor
         #
         # @param name  [String] Widget name
         def initialize(name, controller, path)
           @name = name
           @controller = controller
           @path = path
           self.widget_id = "text:#{name}"
         end

         # Widget label
         #
         # @return [String]
         # @see CWM::AbstractWidget
         def label
           widget_id.to_s
         end
       end

       # This class represents a select widget
       class Select < ::CWM::ComboBox
         # @return [String] Widget name
         attr_reader :name
         # @return [String] Widget items
         attr_reader :items

         class << self
           # Builds a selector widget from a FormElement specification.
           #
           # @param spec [Y2ConfigurationManagement::Salt::FormElement] Element specification
           # @return [Select] New select widget
           def from_spec(spec, controller)
             items = spec.values.each_with_index.map { |v, i| [i.to_s, v] }
             new(spec.name, items, controller, spec.path)
           end
         end

         # Constructor
         #
         # @param name  [String] Widget name
         # @param items [Array<Array<String,Symbol>>] List of options
         def initialize(name, items, controller, path)
           @name = name
           @items = items
           self.widget_id = "select:#{name}"
         end

         # Widget label
         #
         # @return [String]
         # @see CWM::AbstractWidget
         def label
           widget_id.to_s
         end
       end

       # Represents a group of elements
       class Group < ::CWM::CustomWidget
         attr_reader :name, :spec, :children

         class << self
           def from_spec(spec, children, controller)
             new(spec.name, children, controller, spec.path)
           end
         end

         # Constructor
         #
         # @param name     [String] Widget name
         # @param children [Array<AbstractWidget>] Children widgets
         def initialize(name, children, controller, path)
           textdomain "configuration_management"
           @name = name
           @children = children
           @controller = controller
           @path = path
           self.widget_id = "group:#{name}"
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
         # @return [Yast::Term]
         def contents
           VBox(*children)
         end
       end

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
         end

         def selected_row
           row_id = UI.QueryWidget(Id("table_#{name}"), :CurrentItem)
           row_id ? row_id.to_i : nil
         end
       end
     end
   end
 end
