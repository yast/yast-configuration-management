#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/salt/pillar"

describe Y2ConfigurationManagement::Salt::Pillar do
  let(:pillar_path) { FIXTURES_PATH.join("pillar").join("test-formula.sls") }
  subject(:pillar) { described_class.from_file(pillar_path.to_s) }

  describe ".from_file" do
    it "reads the pillar specification from a YAML file" do
      expect(pillar).to be_a(described_class)
    end
  end

  describe ".new" do
    let(:spec) { { person: { name: "John Doe" } } }
    let(:pillar) { described_class.new(spec) }

    it "creates a new #{described_class} instance from the given specification" do
      expect(pillar).to be_a(described_class)
    end
  end

  describe "#data" do
    it "returns the pillar data" do
      expect(pillar.data["person"]["name"]).to eql("Jane Doe")
    end
  end
end
