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
require "y2configuration_management/salt/formula_configuration"
require "y2configuration_management/salt/formula"

require "cwm/rspec"

describe Y2ConfigurationManagement::Salt::FormulaConfiguration do
  let(:formulas_root) { FIXTURES_PATH.join("formulas-ng") }
  let(:formulas) { Y2ConfigurationManagement::Salt::Formula.all(formulas_root.to_s, reload: true) }
  let(:formula) { formulas[0] }
  let(:controller) do
    instance_double("Y2ConfigurationManagement::Salt::FormController", show_main_dialog: :cancel)
  end

  subject(:sequence) { described_class.new(formulas) }

  describe "#run" do
    context "when there are no formulas to be configured" do
      before do
        formulas.each { |f| allow(f).to receive(:enabled?).and_return(false) }
      end

      it "returns :cancel" do
        expect(sequence.run).to eql(:cancel)
      end
    end

    context "when there are at least one formula to be configured" do
      let(:config_result) { :next }

      before do
        formula.enabled = true
        allow(Y2ConfigurationManagement::Salt::FormController)
          .to receive(:new).with(formula.form, formula.pillar).and_return(controller)
        allow(controller).to receive(:show_main_dialog).and_return(config_result)
      end

      it "shows the Form dialog for each of the formulas" do
        expect(controller).to receive(:show_main_dialog)
        sequence.run
      end

      context "and the configuration is aborted at some point" do
        let(:config_result) { :abort }
        it "returns :abort" do
          expect(sequence.run).to eql(:abort)
        end
      end

      context "and going back from the first formula" do
        let(:config_result) { :back }

        it "returns :back" do
          expect(sequence.run).to eql(:back)
        end
      end

      context "and all the formulas are configured" do
        let(:config_result) { :next }

        it "returns :next" do
          expect(sequence.run).to eql(:next)
        end
      end
    end
  end
end
