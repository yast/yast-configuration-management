Yast.import "CWM"

module Yast
  module CM
    module Dialogs
      module IntHelper
        # IntField needs limits, and the machine limits
        # N_BYTES = [42].pack('i').size
        # N_BITS = N_BYTES * 16
        # do not work when passed down to ycp.
        # Use 32 bit min/max, as for a form, should be enough.
        N_BITS = 32
        MAX = 2 ** (N_BITS - 2) - 1
        MIN = -MAX - 1
      end

      class Formula < ::CWM::CustomWidget
        attr_accessor :formula
        attr_accessor :current_group

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

        def handle(event)
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
            if v['$type'] == 'group'
              Item(Id(path + '.' + k), k, true, build_group_tree_widget_items(path + '.' + k, v).compact)
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
            build_group_tree_widget_items('', form)
          )
        end

        def build_form_element(name, element, default)
          return nil if name[0] == '$'

          opts = [:hstretch]
          # this does not work at the group level yet
          case element['$scope']
          when 'readonly'
            opts << :disabled
          end

          widget = case element['$type']
                   when 'group'
                     # We don't render the subgroup as it is in the tree
                   when 'boolean'
                     Left(CheckBox(Id(name.to_sym), Opt(*opts), _(name), element['$default'] == 'true'))
                   when 'select'
                     Left(ComboBox(Id(name.to_sym), Opt(*opts), _(name), element['$values'].map{|x| Item(x)}))
                   when 'password'
                     Password(Id(name.to_sym), Opt(*opts), _(name), element.fetch('$default', '').to_s)
                   when 'number'
                     IntField(Id(name.to_sym), _(name), IntHelper::MIN, IntHelper::MAX, element.fetch('$default', 0).to_i)
                   else
                     InputField(Id(name.to_sym), Opt(*opts), _(name), default.to_s)
                   end
          widget
        end

        def build_form_widget(form, values)
          form_widgets = form.map do |key, element|
            default = values ? values.fetch(key, nil) : element.fetch('$default', '')
            build_form_element(key, element, default)
          end
          form_widgets.compact!
          VBox(*form_widgets, VStretch())
        end
      end
    end
  end
end
