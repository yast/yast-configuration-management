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
require "y2configuration_management/configurations/salt"
require "tmpdir"
require "cwm/rspec"

describe Y2ConfigurationManagement::Salt::FormulaSequence do
  let(:selector) { instance_double(Y2ConfigurationManagement::Salt::FormulaSelection, run: :next) }
  let(:formula_config_sequence) do
    instance_double(Y2ConfigurationManagement::Salt::FormulaConfiguration, run: :abort)
  end
  let(:config) do
    Y2ConfigurationManagement::Configurations::Salt.new_from_hash(
      "formulas_sets" => [
        {
          "metadata_root" => metadata_root.to_s,
          "pillar_root"   => pillar_root.to_s
        }
      ]
    )
  end
  let(:tmpdir) { Pathname(Dir.mktmpdir) }
  let(:work_dir) { tmpdir.join("work_dir") }
  let(:formulas_root) { tmpdir.join("formulas") }
  let(:pillar_root) { formulas_root.join("pillar") }
  let(:metadata_root) { formulas_root.join("metadata") }
  let(:reverse) { false }

  subject(:sequence) { described_class.new(config, reverse: reverse, require_formulas: true) }

  before do
    allow(config).to receive(:work_dir).and_return(work_dir)
    allow(Y2ConfigurationManagement::Salt::FormulaConfiguration)
      .to receive(:new).with(Array, reverse: reverse).and_return(formula_config_sequence)

    FileUtils.mkdir_p(formulas_root.join("metadata"))
    FileUtils.cp_r(FIXTURES_PATH.join("formulas-ng").glob("*"), metadata_root)
    FileUtils.mkdir_p(formulas_root.join("pillar"))
  end

  after do
    FileUtils.remove_entry_secure(tmpdir)
  end

  describe "#run" do
    context "if the user aborts during the process" do
      before do
        allow(sequence).to receive(:choose_formulas).and_return(:abort)
      end

      it "returns :abort" do
        expect(sequence.run).to eql(:abort)
      end

      it "does not write any pillar data" do
        expect(sequence).to_not receive(:write_data)
        sequence.run
      end
    end

    context "if the user selects and configures all the formulas" do
      before do
        allow(sequence).to receive(:choose_formulas).and_return(:next)
        allow(sequence).to receive(:configure_formulas).and_return(:next)
      end

      it "writes the pillars associated to the selected formulas" do
        expect(sequence).to receive(:write_data)
        sequence.run
      end
    end

    context "when running in reverse order" do
      let(:reverse) { true }

      it "starts at the end of the formulas configuration step" do
        expect(sequence).to_not receive("choose_formulas")
        expect(formula_config_sequence).to receive(:run).and_return(:abort)
        sequence.run
      end
    end
  end

  describe "#choose_formulas" do
    before do
      allow(Yast::Report).to receive(:Error)
      allow(Y2ConfigurationManagement::Salt::FormulaSelection)
        .to receive(:new).with(Array).and_return(selector)
    end

    it "runs the formula selection dialog" do
      expect(selector).to receive(:run)
      sequence.choose_formulas
    end

    it "returns :next" do
      expect(sequence.choose_formulas).to eq(:next)
    end

    context "when some formulas are already enabled via config" do
      before do
        allow(config).to receive(:enabled_states).and_return(["test-formula"])
      end

      it "enables the formulas" do
        sequence.choose_formulas
        enabled_formulas = sequence.formulas.select(&:enabled?)
        expect(enabled_formulas.map(&:id)).to eq(["test-formula"])
      end

      it "does not ask the user to select the formulas" do
        expect(selector).to_not receive(:run)
        sequence.choose_formulas
      end
    end

    context "when there are not formulas available in the system" do
      before do
        FileUtils.rm_r(metadata_root)
      end

      it "reports an error" do
        expect(Yast::Report).to receive(:Error).with(/There are no formulas available/)
        sequence.choose_formulas
      end

      it "returns :abort" do
        expect(sequence.choose_formulas).to eql(:abort)
      end

      context "but formulas are not required" do
        subject(:sequence) { described_class.new(config, require_formulas: false) }

        it "does not report any error" do
          expect(Yast::Report).to_not receive(:Error)
          sequence.choose_formulas
        end

        it "returns :finish" do
          expect(sequence.choose_formulas).to eql(:finish)
        end
      end
    end
  end

  describe "#configure_formulas" do
    it "runs the formulas configuration sequence" do
      expect(formula_config_sequence).to receive(:run)
      sequence.configure_formulas
    end

    context "when running in reverse order" do
      let(:reverse) { true }

      it "runs the formulas configuration sequence in reverse order" do
        allow(Y2ConfigurationManagement::Salt::FormulaConfiguration)
          .to receive(:new).with(Array, reverse: true).and_return(formula_config_sequence)
        sequence.configure_formulas
      end
    end
  end

  describe "#write_data" do
    context "when no formula was selected to be applied" do
      it "returns :next without notifying" do
        expect(Yast::Popup).to_not receive(:Feedback)
        expect(sequence.write_data).to eql(:next)
      end
    end

    context "when a formula was selected to be applied" do
      before do
        sequence.formulas[0].enabled = true
      end

      it "writes the pillar data" do
        sequence.write_data
        files = pillar_root.glob("*")
        expect(files.map(&:to_s)).to contain_exactly(
          sequence.formulas[0].pillar.path.to_s
        )
      end

      it "popups a feedback message" do
        expect(Yast::Popup).to receive(:Feedback)
        sequence.write_data
      end

      it "returns :next" do
        allow(Yast::Popup).to receive(:Feedback)
        expect(sequence.write_data).to eql(:next)
      end
    end
  end
end
