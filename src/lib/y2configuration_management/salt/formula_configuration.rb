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
require "y2configuration_management/salt/form_controller"

# @!macro [new] seeSequence
#   @see https://www.rubydoc.info/github/yast/yast-yast2/UI/Sequence
module Y2ConfigurationManagement
  module Salt
    # This class iterates over all the enabled [Formula]s running the
    # [FormController] for each of them.
    class FormulaConfiguration < UI::Sequence
      attr_reader :formulas

      # Constructor
      #
      # @macro seeSequence
      # @param formulas [Array<Formula>]
      def initialize(formulas)
        textdomain "configuration_management"
        @formulas = formulas.select(&:enabled?)
      end

      # @macro seeSequence
      def run
        return :cancel if formulas.empty?
        super(aliases: aliases_hash, sequence: sequence_hash)
      end

    private

      # @param current_index [Integer]
      def next_formula(current_index)
        f = formulas[current_index + 1]
        f ? f.id : :next
      end

      # @param current_index [Integer]
      def previous_formula(current_index)
        return :back if current_index.zero?
        formulas[current_index - 1].id
      end

      # @return [Hash]
      def aliases_hash
        formulas.each_with_object({}) { |f, h| h[f.id] = ->() { configure_formula(f) } }
      end

      # @return [Hash]
      def sequence_hash
        sequence = { START => formulas[0].id }
        formulas.each_with_index do |formula, idx|
          sequence[formula.id] = {
            next:   next_formula(idx),
            back:   previous_formula(idx),
            cancel: :cancel
          }
        end
        sequence
      end

      # Opens the {FormController} main dialog for filling the the given
      # {Formula} {Form}
      #
      # @param formula [Formula]
      def configure_formula(formula)
        controller = FormController.new(formula)
        controller.show_main_dialog
      end
    end
  end
end
