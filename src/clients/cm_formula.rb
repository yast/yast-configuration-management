require 'yaml'
require 'pathname'
require "yast"
require "ui/dialog"

module CM
  class CMClient < Yast::Client

    FORMULA_BASE_DIR = '/space/git/formulas'
    
    include Yast::Logger
    extend Yast::I18n
    def main
      textdomain "cm"
      import_modules

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
      
      read_formulas
      ret = start_workflow
      Wizard.CloseDialog
      ret
    end

    def start_workflow
      sequence = {
        'ws_start' => 'choose_formulas',
        'choose_formulas' => {
          abort: :abort,
          next: @formulas[0]
        }
      }

      workflow_aliases = {
        'choose_formulas' => ->() { choose_formulas },
        'apply_formulas' => ->() { apply_formulas }
      }

      @formulas.each_with_index do |formula, idx|
        sequence[formula] = {
          abort:  :abort,
#          skip:   @formulas[idx + 1],
          cancel: 'choose_formulas',
          next:   idx < @formulas.size - 1 ? @formulas[idx + 1] : 'apply_formulas'
        }
        workflow_aliases[formula] = ->() { parametrize_formula(formula) }
      end
      
      log.info "Starting formula sequence"
      log.info workflow_aliases.inspect
      log.info sequence.inspect
      
      Sequencer.Run(workflow_aliases, sequence)
    end

    def read_formulas
      @formulas = Dir.glob(FORMULA_BASE_DIR + '/*').map{|x| Pathname.new(x).basename.to_s}
    end

    def choose_formulas
      Yast::Wizard.SetContents(
        # dialog title
        _('Formulas'),
        VBox(
          VSpacing(1.0),
          Frame(
            _('Choose which formulas to apply:'),
            *@formulas.map {|formula| Left(CheckBox(formula))}
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

    # Builds the group tree UI widget tems
    # Needs a starting path for the ids ('')
    def build_group_tree_items(path, h)
      h.map do |k, v|
        if v['$type'] == 'group'
          Item(Id(path + '.' + k), k, true, build_group_tree_items(path + '.' + k, v).compact)
        end
      end
    end

    # Builds the group tree UI widget
    def build_group_tree(h)
      Tree(Id(:group_tree), "Groups", build_group_tree_items('', h))
    end

    def build_form_element(name, element)
      case element['$type']
      when 'group'
        Frame(
          _(name),
          VBox(
          *element.reject {|k| k[0] == '$'}
             .map { |k, v| build_form_element(k,v) })
        )
      when 'boolean'
        Left(CheckBox(Id(name.to_sym), _(name), element['$default'] == 'true'))
      when 'select'
        Left(ComboBox(Id(name.to_sym), _(name), element['$values'].map{|x| Item(x)}))
      else
        InputField(Id(name.to_sym), Opt(:hstretch), _(name))
      end
    end
    
    def build_form(formula)
      formula_dir = File.join(FORMULA_BASE_DIR, formula)
      metadata_filename = File.join(formula_dir, 'metadata.yml')
      metadata = YAML::load(File.read(metadata_filename))
      form_filename = File.join(formula_dir, 'form.yml')
      form  = YAML::load(File.read(form_filename))

      log.error form.inspect
      form_widgets = form.map { |key, val| build_form_element(key, val) }
      log.info form_widgets.inspect
      #return VBox(*form_widgets)
      return HBox(
               build_group_tree(form),
               VBox(*form_widgets))
    end
    
    def parametrize_formula(formula)
      Yast::Wizard.SetContents(
        # dialog title
        _(formula),
        build_form(formula),
        "",
        false,
        false
      )
      Convert.to_symbol(UI.UserInput)
    end

    def apply_formulas
      Yast::Wizard.SetContents(
        _("Applying formulas"),
        Label(_(formula)),
        "",
        false,
        false
      )
      Convert.to_symbol(UI.UserInput)
    end

  end
end

CM::CMClient.new.main
