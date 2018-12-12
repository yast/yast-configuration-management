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

Yast.import "Report"
Yast.import "Message"
Yast.import "Popup"

# @!macro [new] seeSequence
#   @see https://www.rubydoc.info/github/yast/yast-yast2/UI/Sequence
module Y2ConfigurationManagement
  module Salt
    # This class is reponsible of running the sequence for selecting the Salt
    # {Formula}s to be applied, configuring all the {Formula}s through its
    # {Form}s and applying the selected {Formula}s to the system.
    class FormulaSequence < UI::Sequence
      # @return [Array<Formula>] available on the system
      attr_reader :formulas

      # Constructor
      #
      # @macro seeSequence
      # @param formulas [Array<Formula>]
      def initialize(formulas)
        textdomain "configuration_management"
        @formulas = formulas
      end

      # @macro seeSequence
      def run
        super(sequence: sequence_hash)
      end

      # It runs the {FormulaSelection} dialog
      def choose_formulas
        if Array.new(formulas).empty?
          Yast::Report.Error(_("There are no formulas available. Please check the log files."))
          return :abort
        end

        Y2ConfigurationManagement::Salt::FormulaSelection.new(formulas).run
      end

      # Iterates over the enabled {Formula}s running the {FormController} for
      # each of them.
      def configure_formulas
        Y2ConfigurationManagement::Salt::FormulaConfiguration.new(formulas).run
      end

      # Apply selected {Formula}s to the current system
      #
      # TODO: Pending implementation
      def apply_formulas
        return :next if formulas.select(&:enabled?).empty?
        Yast::Popup.Feedback(_("Applying formulas"), Yast::Message.takes_a_while) do
          formulas.select(&:enabled?).each { |f| f.write_pillar }
        end
        :next
      end

    private

      # @macro seeSequence
      def sequence_hash
        {
          START                => "choose_formulas",
          "choose_formulas"    => {
            abort: :abort,
            next:  "configure_formulas"
          },
          "configure_formulas" => {
            cancel: "choose_formulas",
            abort:  :abort,
            next:   "apply_formulas"
          },
          "apply_formulas"     => {
            abort: :abort,
            next:  :finish
          }
        }
      end
    end
  end
end
