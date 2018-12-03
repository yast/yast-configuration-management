#!/usr/bin/env rspec

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

require_relative "../../spec_helper"
require "y2configuration_management/salt/formula_sequence"
require "y2configuration_management/salt/formula"

require "cwm/rspec"

describe Y2ConfigurationManagement::Salt::FormulaSequence do
  let(:formulas_root) { FIXTURES_PATH.join("formulas-ng") }
  let(:form) { formulas_root.join("form.yml") }
  let(:formulas) { Y2ConfigurationManagement::Salt::Formula.all(formulas_root.to_s) }
  subject(:sequence) { described_class.new(formulas) }

  describe "#run" do
    context "if the user aborts during the process" do
      before do
        allow(sequence).to receive(:choose_formulas).and_return(:abort)
      end

      it "returns :abort" do
        expect(sequence.run).to eql(:abort)
      end

      it "does not apply any salt state" do
        expect(sequence).to_not receive(:apply_formulas)
        sequence.run
      end
    end

    context "if the user selects and configures all the formulas" do
      before do
        allow(sequence).to receive(:choose_formulas).and_return(:next)
        allow(sequence).to receive(:configure_formulas).and_return(:next)
      end

      it "applies the salt states" do
        expect(sequence).to receive(:apply_formulas)
        sequence.run
      end
    end
  end
end
