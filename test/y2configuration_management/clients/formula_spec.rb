#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/clients/formula"

Yast.import "WFM"

describe Y2ConfigurationManagement::Clients::Formula do
  let(:sequence) { instance_double(Y2ConfigurationManagement::Salt::FormulaSequence) }
  describe "#main" do
    before do
      allow(subject).to receive(:configure_directories)
      allow(subject).to receive(:read_formulas)
      allow(subject).to receive(:start_workflow)
      allow(subject).to receive(:write_formulas)
      allow(Y2ConfigurationManagement::Salt::FormulaSequence)
        .to receive(:new).and_return(sequence)
    end

    it "configures Salt directories" do
      expect(subject).to receive(:configure_directories)
      subject.main
    end

    it "reads the available formulas in the system" do
      expect(subject).to receive(:read_formulas)
      subject.main
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
