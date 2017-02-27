Yast.import "CWM"

module Yast
  module CM
    module Dialogs
      class Formula < ::CWM::CustomWidget
        attr_accessor :formula
        attr_accessor :current_group

        # IntField needs limits, and the machine limits
        # N_BYTES = [42].pack('i').size
        # N_BITS = N_BYTES * 16
        # do not work when passed down to ycp.
        # Use 32 bit min/max, as for a form, should be enough.
        INT_N_BITS = 32
        INT_MAX = 2**(INT_N_BITS - 2) - 1
        INT_MIN = -INT_MAX - 1

        def initialize(formula)
          self.formula = formula
          self.current_group = ".#{formula.form.keys.first}"
        end

        # Dialog content
        #
        # @return [Yast::Term] Terms representing the form content
        def contents
          widget = form_group_widget(formula, current_group)
          HBox(
            HWeight(1, tree_widget(formula.form)),
            HWeight(4, ReplacePoint(Id(:widget), widget))
          )
        end

        # Save group information into the formula
        def save(group)
          keys = formula.form_for_group(current_group).keys.reject { |k| k.start_with?("$") }
          values = keys.each_with_object({}) do |key, all|
            all[key] = Yast::UI.QueryWidget(Id(key.to_sym), :Value)
          end
          formula.set_values_for_group(group, values)
        end

        # Dialog result
        #
        # @return [Yast::CM::Salt::Formula] Formula
        # @see #formula
        def result
          formula
        end

        def store
          save(current_group)
        end

        def handle(_event)
          new_group = Yast::UI.QueryWidget(:group_tree, :CurrentItem)
          save(current_group)
          return nil if current_group == new_group
          self.current_group = new_group
          widget = form_group_widget(formula, current_group)
          Yast::UI.ReplaceWidget(Id(:widget), widget)
          nil
        end

        # Builds the group tree UI widget tems
        # Needs a starting path for the ids ('')
        def build_group_tree_widget_items(path, form)
          form.map do |k, v|
            if v["$type"] == "group"
              Item(Id(path + "." + k), k, true, build_group_tree_widget_items(path + "." + k, v).compact)
            end
          end
        end

        # to keep the entered data we need to cache the widgets
        def form_group_widget(formula, group)
          build_form_widget(
            formula.form_for_group(group), formula.values_for_group(group)
          )
        end

        # Builds the group tree UI widget for this
        def tree_widget(form)
          Tree(
            Id(:group_tree),
            Opt(:notify, :immediate),
            "Groups",
            build_group_tree_widget_items("", form)
          )
        end

        def build_form_element(name, element, default)
          return nil if name[0] == "$" || element["$type"] == "group"

          opts = [:hstretch]
          # this does not work at the group level yet
          case element["$scope"]
          when "readonly"
            opts << :disabled
          end

          meth = "build_#{element["$type"]}_element"
          meth = :build_element unless respond_to?(meth)
          send(meth, name, element, default, opts)
        end


        def build_boolean_element(name, _element, value, opts = [])
          Left(CheckBox(Id(name.to_sym), Opt(*opts), _(name), value == true))
        end

        def build_select_element(name, element, value, opts = [])
          items = element["$values"].map { |i| Item(Id(i), i, i == value) }
          Left(ComboBox(Id(name.to_sym), Opt(*opts), _(name), items))
        end

        def build_password_element(name, _element, value, opts = [])
          Password(Id(name.to_sym), Opt(*opts), _(name), value.to_s)
        end

        def build_element(name, _element, value, opts = [])
          InputField(Id(name.to_sym), Opt(*opts), _(name), value.to_s)
        end

        def build_number_element(name, _element, value, opts = [])
          IntField(Id(name.to_sym), Opt(*opts), _(name), INT_MIN, INT_MAX, value.to_i)
        end

        def build_form_widget(form, values)
          form_widgets = form.map do |key, element|
            default = values ? values.fetch(key, nil) : element.fetch("$default", "")
            build_form_element(key, element, default)
          end
          form_widgets.compact!
          VBox(*form_widgets, VStretch())
        end
      end
    end
  end
end
