require 'yaml'
require 'pathname'
require "yast"
require "ui/dialog"

module CM

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

  # Helper to create UI from a formula
  module FormulaHelper
    extend Yast::UIShortcuts
    extend Yast::I18n

    # Builds the group tree UI widget tems
    # Needs a starting path for the ids ('')
    def self.build_group_tree_widget_items(path, form)
      form.map do |k, v|
        if v['$type'] == 'group'
          Item(Id(path + '.' + k), k, true, build_group_tree_widget_items(path + '.' + k, v).compact)
        end
      end
    end

    # Builds the group tree UI widget for this
    def self.build_group_tree_widget(form)
      Tree(Id(:group_tree), Opt(:notify, :immediate), "Groups", build_group_tree_widget_items('', form))
    end

    def self.build_form_element(name, element)
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
               #  Frame(
               #    _(name),
               #    VBox(
               #    *element.reject {|k| k[0] == '$'}
               #       .map { |k, v| build_form_element(k,v) })
               #  )
               when 'boolean'
                 Left(CheckBox(Id(name.to_sym), Opt(*opts), _(name), element['$default'] == 'true'))
               when 'select'
                 Left(ComboBox(Id(name.to_sym), Opt(*opts), _(name), element['$values'].map{|x| Item(x)}))
               when 'password'
                 Password(Id(name.to_sym), Opt(*opts), _(name), element.fetch('$default', '').to_s)
               when 'number'
                 IntField(Id(name.to_sym), _(name), IntHelper::MIN, IntHelper::MAX, element.fetch('$default', 0).to_i)
               else
                 InputField(Id(name.to_sym), Opt(*opts), _(name), element.fetch('$default', '').to_s)
               end
      widget
    end

    def self.build_form_widget(form)
      form_widgets = form.map { |key, val| build_form_element(key, val) }.compact
      return VBox(*form_widgets, VStretch())
    end

  end

  # A formula on disk
  class Formula
    FORMULA_BASE_DIR = '/space/git/formulas'

    def initialize(path)
      @path = path

      metadata_filename = File.join(@path, 'metadata.yml')
      metadata = YAML::load(File.read(metadata_filename))
      form_filename = File.join(@path, 'form.yml')
      @form = YAML::load(File.read(form_filename))
    end

    def name
      @path.basename.to_s
    end

    # retrieves the form data for this formula
    def form
      @form
    end

    # retrieves the sub form data for a given form group path
    def form_for_group(group)
      groups = group.split('.').drop(1)
      groups.inject(@form) do |m, g|
          m[g.to_s]
      end
    end

    # Return all the installed formulas
    def self.all
      Dir.glob(FORMULA_BASE_DIR + '/*')
        .map{|p| Pathname.new(p)}
        .map{|p| Formula.new(p) }
    end
  end

  class CMFormula < Yast::Client
    include Yast::Logger
    extend Yast::I18n

    def main
      textdomain "cm"
      import_modules

      # widget cache indexed by formula name and group name
      @widgets = Hash.new { |h, k| h[k] = { } }

      @cmdline_description = {
        "id"         => "cm_formulas",
        "guihandler" => fun_ref(method(:Main), "symbol ()")
      }

      CommandLine.Run(@cmdline_description)
    end

    def import_modules
      Yast.import "CommandLine"
      Yast.import "UI"
      Yast.import "Popup"
      Yast.import "GetInstArgs"
      Yast.import "Wizard"
      Yast.import "Mode"
      Yast.import "Stage"
      Yast.import "Label"
      Yast.import "Sequencer"
      Yast.import "Installation"
    end

    def Main
      Wizard.CreateDialog
      Wizard.SetDesktopIcon("security")
      # dialog caption
      Wizard.SetContents(_("Initializing..."), Empty(), "", false, true)

      @formulas = Formula.all
      ret = start_workflow
      Wizard.CloseDialog
      ret
    end

    def start_workflow
      sequence = {
        'ws_start' => 'choose_formulas',
        'choose_formulas' => {
          abort: :abort,
          next: @formulas[0].name
        }
      }

      workflow_aliases = {
        'choose_formulas' => ->() { choose_formulas },
        'apply_formulas' => ->() { apply_formulas }
      }

      @formulas.each_with_index do |formula, idx|
        sequence[formula.name] = {
          abort:  :abort,
          cancel: 'choose_formulas',
          next:   idx < @formulas.size - 1 ? @formulas[idx + 1].name : 'apply_formulas'
        }
        workflow_aliases[formula.name] = ->() { parametrize_formula(formula) }
      end

      log.info "Starting formula sequence"
      log.info workflow_aliases.inspect
      log.info sequence.inspect

      Sequencer.Run(workflow_aliases, sequence)
    end

    def choose_formulas
      Yast::Wizard.SetContents(
        # dialog title
        _('Formulas'),
        VBox(
          VSpacing(1.0),
          Frame(
            _('Choose which formulas to apply:'),
            *@formulas.map {|formula| Left(CheckBox(formula.name))}
          ),
          VStretch(),
        ),
        _("Select which formulas you want to apply to this machine. For each selected formula, you will"\
          " be able to customize it with parameters"),
        false,
        true
      )
      Wizard.RestoreNextButton
      Convert.to_symbol(UI.UserInput)
    end

    # to keep the entered data we need to cache the widgets
    def form_group_widget_from_cache(formula, group)
      unless @widgets[formula.name][group]
        @widgets[formula.name][group] = FormulaHelper.build_form_widget(formula.form_for_group(group))
      end
      @widgets[formula.name][group]
    end
    
    def parametrize_formula(formula)
      group_tree = FormulaHelper.build_group_tree_widget(formula.form)
      Yast::Wizard.SetContents(
        # dialog title
        _(formula.name),
        HBox(
          HWeight(1, group_tree),
          HWeight(2, ReplacePoint(Id(:form_content), Empty()))),
        "",
        false,
        false
      )
      # first group
      current_group = UI.QueryWidget(:group_tree, :CurrentItem)
      widget = form_group_widget_from_cache(formula, current_group)
      UI.ReplaceWidget(:form_content, widget)

      loop do
        ev_widget = Convert.to_symbol(UI.UserInput)
        log.info ev_widget.to_s
        break unless ev_widget == :group_tree
        current_group = UI.QueryWidget(:group_tree, :CurrentItem)
        widget = form_group_widget_from_cache(formula, current_group)

        UI.ReplaceWidget(:form_content, widget)
        log.info current_group.to_s
      end
    end

    def apply_formulas
      Yast::Wizard.SetContents(
        _("Applying formulas"),
        Label(_(formula)),
        "",
        false,
        false
      )
    end

  end
end

CM::CMFormula.new.main
