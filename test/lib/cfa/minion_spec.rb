#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/cfa/minion"
require "tmpdir"

describe Yast::ConfigurationManagement::CFA::Minion do
  EXAMPLE_PATH = FIXTURES_PATH.join("salt", "minion").to_s.freeze

  subject(:config) { Yast::ConfigurationManagement::CFA::Minion.new }
  let(:path) { EXAMPLE_PATH }

  before do
    stub_const("Yast::ConfigurationManagement::CFA::Minion::PATH", path)
    config.load if File.exist?(path)
  end

  describe "#master" do
    it "returns master server name" do
      expect(config.master).to eq("salt")
    end
  end

  describe "#master=" do
    it "sets the master server name" do
      expect { config.master = "alt" }.to change { config.master }.to("alt")
    end
  end

  describe "#save" do
    let(:tmpdir) { Dir.mktmpdir }
    let(:path) { File.join(tmpdir, "yast-configuration-management.conf") }

    after do
      FileUtils.rm_r(tmpdir) if Dir.exist?(tmpdir)
    end

    context "when the file exists" do
      before { FileUtils.cp(EXAMPLE_PATH, tmpdir) }

      it "updates the file" do
        config.master = "other"
        config.save
        expect(YAML.load_file(path)).to eq({"master" => "other"})
      end
    end

    context "when the file does not exist" do
      it "creates the file" do
        config.master = "other"
        config.save
        expect(YAML.load_file(path)).to eq({"master" => "other"})
        expect(File.exist?(path)).to eq(true)
      end
    end

    context "when the directory does not exist" do
      let(:path) { File.join(tmpdir, "minion.d", "yast-configuration-management.conf") }

      it "creates the directory and the file" do
        config.master = "other"
        config.save
        expect(YAML.load_file(path)).to eq({"master" => "other"})
        expect(File.exist?(path)).to eq(true)
      end
    end
  end
end
