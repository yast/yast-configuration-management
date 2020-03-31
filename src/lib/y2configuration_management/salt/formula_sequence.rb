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

require "ui/sequence"
require "y2configuration_management/salt/formula_configuration"
require "y2configuration_management/salt/formula_selection"
require "y2configuration_management/salt/formula"
require "y2configuration_management/cfa/salt_top"

Yast.import "Report"
Yast.import "Message"
Yast.import "Popup"

# @!macro [new] seeSequence
#   @see https://www.rubydoc.info/github/yast/yast-yast2/UI/Sequence
module Y2ConfigurationManagement
  module Salt
    # This class is reponsible of running the sequence for selecting the Salt
    # {Formula}s to be applied, configuring all the {Formula}s through its
    # {Form}s and write the {Pillar}s data associated to each of the selected
    # {Formula}s into the system.
    class FormulaSequence < UI::Sequence
      # @return [Array<Formula>] available on the system
      attr_reader :formulas

      # @return [Y2ConfigurationManagement::Configurations::Salt]
      attr_reader :config

      # Constructor
      #
      # @macro seeSequence
      # @param config  [Yast::ConfigurationManagement::Configurations::Salt]
      # @param reverse [Boolean] Runs the sequence in reverse order
      # @param require_formulas
      def initialize(config, reverse: false, require_formulas: false)
        textdomain "configuration_management"
        @config = config
        @reverse = reverse
        @require_formulas = require_formulas
        read_formulas
      end

      # @macro seeSequence
      def run
        super(sequence: sequence_hash)
      end

      # It runs the {FormulaSelection} dialog
      def choose_formulas
        return handle_no_formulas if Array.new(formulas).empty?

        if config.enabled_states.empty?
          enable_formulas_by_user
        else
          enable_formulas_by_config
          :next
        end
      end

      # Iterates over the enabled {Formula}s running the {FormController} for
      # each of them.
      def configure_formulas
        Y2ConfigurationManagement::Salt::FormulaConfiguration.new(formulas, reverse: reverse).run
      end

      # Write the data associated to the selected {Formula}s into the current system
      def write_data
        return :next if formulas.select(&:enabled?).empty?

        [config.pillar_root, config.states_root].each do |path|
          ::FileUtils.mkdir_p(path) unless File.exist?(path)
          top = Y2ConfigurationManagement::CFA::SaltTop.new(path: File.join(path, "top.sls"))
          top.load
          top.add_states(formulas.select(&:enabled?).map(&:id))
          top.save
        end

        Yast::Popup.Feedback(_("Writing formulas data"), Yast::Message.takes_a_while) do
          formulas.select(&:enabled?).each(&:write_pillar)
        end

        :next
      end

    private

      attr_reader :reverse, :require_formulas

      # @macro seeSequence
      def sequence_hash
        {
          START                => reverse ? "configure_formulas" : "choose_formulas",
          "choose_formulas"    => {
            abort:  :abort,
            next:   "configure_formulas",
            back:   :back,
            finish: :finish
          },
          "configure_formulas" => {
            cancel: "choose_formulas",
            abort:  :abort,
            next:   "write_data"
          },
          "write_data"         => {
            abort: :abort,
            next:  :finish
          }
        }
      end

      # It reads all the available {Formula}s in the system initializing also
      # the {Pillar} associated with each one
      def read_formulas
        @formulas = Y2ConfigurationManagement::Salt::Formula.all(config.formulas_roots.map(&:to_s))
        @formulas.each { |f| f.pillar = pillar_for(f) }
      end

      # Convenience method for reading the {Pillar} associated to the given
      # formula
      #
      # @param formula [Formula]
      # @return [Pillar]
      def pillar_for(formula)
        pillar_file = File.join(config.pillar_root, "#{formula.id}.sls")
        pillar = Y2ConfigurationManagement::Salt::Pillar.new(data: {}, path: pillar_file)
        pillar.load
        pillar
      end

      # Asks the user to select the enabled formulas/states
      def enable_formulas_by_user
        Y2ConfigurationManagement::Salt::FormulaSelection.new(formulas).run
      end

      # Sets the list of enabled formulas/states according to the given configuration
      def enable_formulas_by_config
        formulas
          .select { |f| config.enabled_states.include?(f.id) }
          .each { |f| f.enabled = true }
      end

      # Handles the case where there are no formulas
      #
      # FIXME: reading formulas should be done outside this sequence so we can
      # decide outside how to deal with this case.
      #
      # @return [Symbol] Symbol that the sequence should return
      def handle_no_formulas
        return :finish unless require_formulas
        Yast::Report.Error(_("There are no formulas available. Please check the log files."))
        :abort
      end
    end
  end
end
