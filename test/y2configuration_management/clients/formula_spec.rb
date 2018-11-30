#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/clients/formula"

Yast.import "WFM"

describe Y2ConfigurationManagement::Clients::Formula do
  describe "#main" do
    let(:formulas_root) { FIXTURES_PATH.join("formulas") }
    before do
      allow(subject).to receive(:import_modules)
      allow(subject).to receive(:configure_directories)
      allow(subject).to receive(:read_formulas)
      allow(subject).to receive(:start_workflow)
      allow(subject).to receive(:formulas_root).and_return(formulas_root)
    end

    it "imports the needed modules" do
      expect(subject).to receive(:import_modules)
      subject.main
    end

    it "configures Salt directories" do
      expect(subject).to receive(:configure_directories)
      subject.main
    end

    it "reads the available formulas in the system" do
      expect(subject).to receive(:configure_directories)
      subject.main
    end

    it "starts the workflow for selecting, configuraring and applying the system Salt Formulas" do
      expect(subject).to receive(:start_workflow)
      subject.main
    end
  end
end
