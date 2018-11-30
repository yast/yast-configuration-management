require "yast"
require "y2configuration_management/salt/formula"
require "y2configuration_management/salt/form_controller"
require "y2configuration_management/salt/formula_selection"

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
        configure_directories

        # Mechanism to detect if we're going back
        @last_formula_idx = 0

        do_main
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

    private

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
        Y2ConfigurationManagement::Salt::FormulaSelection.new(formulas).run
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
      #
      # TODO: Pending implementation
      def apply_formulas
        return :next if enabled_formulas.empty?

        Yast::Wizard.SetContents(
          _("Applying formulas"),
          Label(enabled_formulas.map(&:name).join(", ")),
          "",
          false,
          false
        )

        sleep 2

        :next
      end

      def configure_directories
        @states_root, @formulas_root, @pillar_root = Yast::WFM.Args()
        @formulas_root ||= Y2ConfigurationManagement::Salt::Formula::FORMULA_BASE_DIR
        @states_root ||= formulas_root + "/states"
        @pillar_root ||= Y2ConfigurationManagement::Salt::Formula::FORMULA_DATA + "/pillar"
      end

      def enabled_formulas
        formulas.select(&:enabled?)
      end

      # Helper method do detect if we're going back
      def going_back?(formula)
        idx = formulas.index(formula)
        ret = idx < @last_formula_idx
        @last_formula_idx = idx
        ret
      end

      def import_modules
        Yast.import "Wizard"
        Yast.import "Mode"
        Yast.import "Label"
        Yast.import "Sequencer"
        Yast.import "Report"
      end
    end
  end
end
