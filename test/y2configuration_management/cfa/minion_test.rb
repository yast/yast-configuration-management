#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/cfa/minion"
require "tmpdir"

describe Y2ConfigurationManagement::CFA::Minion do
  EXAMPLE_PATH = FIXTURES_PATH.join("salt", "minion").to_s.freeze

  subject(:config) { Y2ConfigurationManagement::CFA::Minion.new }
  let(:path) { EXAMPLE_PATH }

  before do
    stub_const("Y2ConfigurationManagement::CFA::Minion::PATH", path)
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
        expect(YAML.load_file(path)).to eq("master" => "other")
      end
    end

    context "when the file does not exist" do
      it "creates the file" do
        config.master = "other"
        config.save
        expect(YAML.load_file(path)).to eq("master" => "other")
        expect(File.exist?(path)).to eq(true)
      end
    end

    context "when the directory does not exist" do
      let(:path) { File.join(tmpdir, "minion.d", "yast-configuration-management.conf") }

      it "creates the directory and the file" do
        config.master = "other"
        config.save
        expect(YAML.load_file(path)).to eq("master" => "other")
        expect(File.exist?(path)).to eq(true)
      end
    end

    describe "#set_file_roots" do
      it "sets file_roots for the base environment" do
        config.set_file_roots(["/path1"])
        expect(config.file_roots("base")).to eq(["/path1"])
      end

      context "when an environment is specified" do
        it "sets file_roots for the given environment" do
          old = config.file_roots("base")
          config.set_file_roots(["/path1"], "test")
          expect(config.file_roots("base")).to eq(old)
          expect(config.file_roots("test")).to eq(["/path1"])
        end
      end
    end

    describe "#set_pillar_roots" do
      it "sets the pillar-roots for the base environment" do
        config.set_pillar_roots(["/srv/pillar"])
        expect(config.pillar_roots("base")).to eq(["/srv/pillar"])
      end

      context "when an environment is specified" do
        it "sets pillar_roots for the given environment" do
          old = config.pillar_roots("base")
          config.set_pillar_roots(["/srv/pillar"], "test")
          expect(config.pillar_roots("base")).to eq(old)
          expect(config.pillar_roots("test")).to eq(["/srv/pillar"])
        end
      end
    end

    describe "#exist?" do
      context "when the file exists" do
        let(:path) { EXAMPLE_PATH }

        it "returns true" do
          expect(config.exist?).to eq(true)
        end
      end

      context "when the file exists" do
        let(:path) { FIXTURES_PATH.join("non-existent") }

        it "returns false" do
          expect(config.exist?).to eq(false)
        end
      end
    end
  end
end
