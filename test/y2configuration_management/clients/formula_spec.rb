#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/clients/formula"

Yast.import "WFM"

describe Y2ConfigurationManagement::Clients::Formula do
  let(:sequence) { instance_double(Y2ConfigurationManagement::Salt::FormulaSequence) }
  let(:states_root) { FIXTURES_PATH.join("salt").to_s }
  let(:formulas_root) { FIXTURES_PATH.join("formulas-ng").to_s }
  let(:pillar_root) { FIXTURES_PATH.join("pillar").to_s }
  let(:directories) { [states_root, formulas_root, pillar_root] }

  describe "#main" do
    before do
      allow(Yast::WFM).to receive(:Args).and_return(directories)
      allow(subject).to receive(:configure_directories).and_call_original
      allow(subject).to receive(:read_formulas)
      allow(subject).to receive(:start_workflow)
      allow(subject).to receive(:write_formulas)
      allow(Y2ConfigurationManagement::Salt::FormulaSequence)
        .to receive(:new).and_return(sequence)
    end

    context "when the states, pillar and formulas directories are given" do
      let(:directories) { ["states_root", "formulas_root", "pillar_root"] }

      it "uses the given directories" do
        subject.main
        directories.each { |d| expect(subject.send(d)).to eql(d) }
      end
    end

    context "when no directories are given" do
      let(:directories) { [] }

      it "uses the defaults" do
        subject.main
        expect(subject.formulas_root)
          .to eql(Y2ConfigurationManagement::Salt::Formula.formula_directories)
      end
    end

    it "reads the available formulas in the system" do
      expect(subject).to receive(:read_formulas).and_call_original
      subject.main
      expect(subject.formulas_root).to eql(formulas_root)
      expect(subject.formulas.size).to eql(2)
      expect(subject.formulas.map(&:id)).to include("test-formula")
    end

    it "starts the workflow for selecting, configuraring and applying the system Salt Formulas" do
      expect(subject).to receive(:start_workflow).and_call_original
      expect(sequence).to receive(:run)
      subject.main
    end

    it "adds the configured formulas to the top state file" do
      expect(subject).to receive(:write_formulas)
      subject.main
    end
  end
end
