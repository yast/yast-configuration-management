require "yaml"
require "pathname"
require "yast"
require "y2configuration_management/salt/formula"
require "y2configuration_management/salt/form_controller"
require "fileutils"
require "configuration_management/cfa/salt_top"

module Y2ConfigurationManagement
  module Clients
    # Client to configure formulas
    class Formula < Yast::Client
      include Yast::Logger
      extend Yast::I18n

      attr_accessor :formulas
      attr_reader :states_root, :formulas_root, :pillar_root

      def main
        textdomain "configuration_management"
        import_modules

        @states_root, @formulas_root, @pillar_root = Yast::WFM.Args()
        @formulas_root ||= Y2ConfigurationManagement::Salt::Formula::FORMULA_BASE_DIR
        @states_root ||= formulas_root + "/states"
        @pillar_root ||= Y2ConfigurationManagement::Salt::Formula::FORMULA_DATA + "/pillar"

        # widget cache indexed by formula name and group name
        @widgets = Hash.new { |h, k| h[k] = {} }

        # Mechanism to detect if we're going back
        @last_formula_idx = 0

        @cmdline_description = {
          "id"         => "configuration_management_formulas",
          "guihandler" => fun_ref(method(:do_main), "symbol ()")
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
        Yast.import "Report"
      end

      def do_main
        Wizard.CreateDialog
        Wizard.SetDesktopIcon("security")
        # dialog caption
        Wizard.SetContents(_("Initializing..."), Empty(), "", false, true)

        self.formulas = Y2ConfigurationManagement::Salt::Formula.all(formulas_root)
        unless formulas && !formulas.empty?
          Yast::Report.Error(_("Formulas cannot not be read. Please check logfiles."))
          return false
        end

        start_workflow
      ensure
        Wizard.CloseDialog
      end

      # This code is still experimental, so let's disable this check.
      # rubocop:disable Metrics/AbcSize
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
            next:   idx < formulas.size - 1 ? formulas[idx + 1].name : "apply_formulas",
            back:   idx > 0 ? formulas[idx - 1].name : "choose_formulas"
          }
          workflow_aliases[formula.name] = ->() { parametrize_formula(formula) }
        end

        log.info "Starting formula sequence"
        log.info "Aliases: #{workflow_aliases.inspect}"
        log.info "Sequence: #{sequence.inspect}"

        Sequencer.Run(workflow_aliases, sequence)
      end

      # This code is still experimental, so let's disable this check.
      # rubocop:disable Metrics/MethodLength
      def choose_formulas
        Yast::Wizard.SetContents(
          # dialog title
          _("Formulas"),
          VBox(
            VSpacing(1.0),
            Frame(
              _("Choose which formulas to apply:"),
              VBox(
                *formulas.map do |f|
                  Left(CheckBox(Id(f.name.to_sym), "#{f.name}: #{f.description}", f.enabled?))
                end
              )
            ),
            VStretch()
          ),
          _("Select which formulas you want to apply to this machine. "\
            "For each selected formula, you will be able to customize it "\
            "with parameters"),
          false,
          true
        )
        Wizard.RestoreNextButton
        loop do
          case Convert.to_symbol(UI.UserInput)
          when :next
            formulas.each do |formula|
              formula.enabled = Convert.to_boolean(UI.QueryWidget(formula.name.to_sym, :Value))
            end
            return :next
          else
            return :abort
          end
        end
      end

      def parametrize_formula(formula)
        if !formula.enabled?
          ret = going_back?(formula) ? :back : :next
          return ret
        end
        @last_formula_idx = formulas.index(formula)

        controller = Y2ConfigurationManagement::Salt::FormController.new(formula.form)
        controller.show_main_dialog
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
          top = Yast::ConfigurationManagement::CFA::SaltTop.new(path: File.join(path, "top.sls"))
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

      # Helper method do detect if we're going back
      def going_back?(formula)
        idx = formulas.index(formula)
        ret = idx < @last_formula_idx
        @last_formula_idx = idx
        ret
      end
    end
  end
end
