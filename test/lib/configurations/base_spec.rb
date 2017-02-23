#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurations/base"
require "tmpdir"

describe Yast::CM::Configurations::Base do
  subject(:config) { Yast::CM::Configurations::Base.new(profile) }

  let(:master) { "some-server.suse.com" }
  let(:auth_attempts) { 3 }
  let(:work_dir) { Pathname.new("/tmp/some-dir") }
  let(:default_path) { FIXTURES_PATH.join("cm-salt.yml") }

  let(:profile) do
    {
      "type"          => "salt",
      "master"        => master,
      "auth_attempts" => 5,
      "auth_time_out" => 10,
      "keys_url"      => "http://internal-server.com/keys.tgz"
    }
  end

  before do
    stub_const("Yast::CM::Configurations::Base::DEFAULT_PATH", default_path)
    allow(Dir).to receive(:mktmpdir).and_return(work_dir.to_s)
  end

  context "default configuration" do
    subject(:config) { Yast::CM::Configurations::Base.new({}) }

    let(:attrs) do
      {
        auth_attempts: 3,
        auth_time_out: 15,
        type:          nil,
        mode:          :masterless,
        work_dir:      work_dir,
        keys_url:      nil
      }
    end

    it { is_expected.to have_attributes(attrs) }
  end

  describe ".load" do
    context "when a path is given" do
      let(:custom_path) { FIXTURES_PATH.join("cm-puppet.yml") }

      it "returns the configuration from the given path" do
        expect(YAML).to receive(:load_file).with(custom_path).and_call_original
        described_class.load(custom_path)
      end
    end

    context "when a path is not given" do
      it "returns the configuration from the default path" do
        expect(default_path).to receive(:exist?).and_return(true)
        expect(YAML).to receive(:load_file).with(default_path).and_call_original
        described_class.load
      end
    end

    context "when the path does not exist" do
      let(:custom_path) { FIXTURES_PATH.join("non-existent.yml") }

      it "returns false" do
        expect(described_class.load(custom_path)).to eq(false)
      end
    end
  end

  describe "#mode" do
    context "when a master server is not specified" do
      let(:master) { nil }

      it "returns :masterless" do
        expect(config.mode).to eq(:masterless)
      end
    end

    context "when a master server is specified" do
      it "returns :client" do
        expect(config.mode).to eq(:client)
      end
    end
  end

  describe "#to_hash" do
    it "returns configuration values" do
      expect(config.to_hash).to eq(
        auth_attempts: profile["auth_attempts"],
        auth_time_out: profile["auth_time_out"],
        keys_url:      URI(profile["keys_url"]),
        mode:          :client,
        master:        profile["master"],
        work_dir:      work_dir
      )
    end

    context "when some values are nil" do
      it "those values are not included" do
        expect(config.to_hash.keys).to_not include(:type)
      end
    end
  end

  describe "#to_secure_hash" do
    it "returns configuration values filtering sensible information" do
      expect(config.to_secure_hash).to eq(
        auth_attempts: profile["auth_attempts"],
        auth_time_out: profile["auth_time_out"],
        mode:          :client,
        master:        profile["master"],
        work_dir:      work_dir
      )
    end
  end

  describe "#write" do
    let(:work_dir) { Pathname.new(Dir.mktmpdir) }
    let(:default_path) { config.work_dir.join("default.yml") }

    before do
      allow(Dir).to receive(:mktmpdir).and_call_original
    end

    after(:each) do
      FileUtils.rm_r(work_dir)
    end

    context "when a path is given" do
      let(:custom_path) { Pathname.new(work_dir).join("custom.yml") }

      it "writes a YAML representation to the given path" do
        config.save(custom_path)
        expect(default_path).to_not be_file
        expect(custom_path).to be_file
        content = YAML.load_file(custom_path)
        expect(content).to eq(config.to_secure_hash)
      end
    end

    context "when a path is not given" do
      it "writes a YAML representation to the default path" do
        config.save
        expect(default_path).to be_file
        content = YAML.load_file(default_path)
        expect(content).to eq(config.to_secure_hash)
      end
    end
  end
end
