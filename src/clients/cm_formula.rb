require "yaml"
require "pathname"
require "yast"
require "cm/salt/formula"
require "cm/dialogs/formula"
require "fileutils"
require "cm/cfa/salt_top"

module CM
  class CMFormula < Yast::Client
    include Yast::Logger
    extend Yast::I18n

    attr_accessor :formulas
    attr_reader :states_root, :formulas_root, :pillar_root

    def main
      textdomain "cm"
      import_modules

      @states_root, @formulas_root, @pillar_root = WFM.Args()

      # widget cache indexed by formula name and group name
      @widgets = Hash.new { |h, k| h[k] = {} }

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

      self.formulas = Yast::CM::Salt::Formula.all(formulas_root)
      ret = start_workflow
      Wizard.CloseDialog
      ret
    end

    def start_workflow
      sequence = {
        "ws_start"        => "choose_formulas",
        "choose_formulas" => {
          abort: :abort,
          next:  formulas[0].name
        },
        "apply_formulas"  => {
          abort: :abort,
          next:  :next
        }
      }

      workflow_aliases = {
        "choose_formulas" => ->() { choose_formulas },
        "apply_formulas"  => ->() { apply_formulas }
      }

      formulas.each_with_index do |formula, idx|
        sequence[formula.name] = {
          abort:  :abort,
          cancel: "choose_formulas",
          next:   idx < formulas.size - 1 ? formulas[idx + 1].name : "apply_formulas"
        }
        workflow_aliases[formula.name] = ->() { parametrize_formula(formula) }
      end

      log.info "Starting formula sequence"
      log.info "Aliases: #{workflow_aliases.inspect}"
      log.info "Sequence: #{sequence.inspect}"

      Sequencer.Run(workflow_aliases, sequence)
    end

    def choose_formulas
      Yast::Wizard.SetContents(
        # dialog title
        _("Formulas"),
        VBox(
          VSpacing(1.0),
          Frame(
            _("Choose which formulas to apply:"),
            VBox(
              *formulas.map { |f| Left(CheckBox(Id(f.name.to_sym), "#{f.name}: #{f.description}")) }
            )
          ),
          VStretch()
        ),
        _("Select which formulas you want to apply to this machine. For each selected formula, you will"\
          " be able to customize it with parameters"),
        false,
        true
      )
      Wizard.RestoreNextButton
      loop do
        case Convert.to_symbol(UI.UserInput)
        when :next
          formulas.each do |formula|
            log.info "#{formula.name}: #{Convert.to_boolean(UI.QueryWidget(formula.name.to_sym, :Value))}"
            formula.enable! if Convert.to_boolean(UI.QueryWidget(formula.name.to_sym, :Value))
          end
          return :next
        else
          return :abort
        end
      end
    end

    def parametrize_formula(formula)
      return :next unless formula.enabled?

      widget = Yast::CM::Dialogs::Formula.new(formula)
      CWM.show(HBox(widget), caption: formula.name)
      :next
    end

    # Apply selected formulas
    def apply_formulas
      Yast::Wizard.SetContents(
        _("Applying formulas"),
        Label(formulas.select(&:enabled?).map(&:name).join(", ")),
        "",
        false,
        false
      )

      enabled_formulas = formulas.select(&:enabled?)
      states = enabled_formulas.map(&:name)
      [pillar_root, states_root].each do |path|
        ::FileUtils.mkdir_p(path) unless File.exist?(path)
        top = Yast::CM::CFA::SaltTop.new(path: File.join(path, "top.sls"))
        top.load
        top.add_states(states)
        top.save
      end

      enabled_formulas.each do |formula|
        pillar_file = File.join(pillar_root, "#{formula.name}.sls")
        File.open(pillar_file, "w+") { |f| f.puts YAML.dump(formula.values) }
      end

      :next
    end
  end
end

CM::CMFormula.new.main
