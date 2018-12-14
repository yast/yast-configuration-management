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
    let(:pillar) { described_class.new(data: spec) }

    it "creates a new #{described_class} instance from the given specification" do
      expect(pillar).to be_a(described_class)
    end
  end

  describe "#data" do
    it "returns the pillar data" do
      expect(pillar.data["person"]["name"]).to eql("Jane Doe")
    end
  end

  describe "#load" do
    subject(:pillar) { described_class.new(path: pillar_path) }

    it "loads its data from the known path" do
      expect(pillar.data).to be_empty
      pillar.load
      expect(pillar.data["person"]["name"]).to eql("Jane Doe")
    end
  end

  describe "#save" do
    let(:pillar_back) { "#{FIXTURES_PATH.join("pillar").join("test-formula.sls")}.back" }

    after do
      FileUtils.rm(pillar_back)
    end

    it "writes the pillar data to its file path" do
      expect(File.read(pillar_path)).to_not include("John Doe")
      pillar.path = pillar_back
      pillar.data["person"]["name"] = "John Doe"
      pillar.save
      expect(File.read(pillar_back)).to include("John Doe")
    end
  end

  describe "#dump" do
    it "does a YAML dump of the pillar data" do
      pillar.data = { "person" => "John Doe" }
      expect(pillar.dump).to eql("---\nperson: John Doe\n")
    end
  end
end
