#!/usr/bin/env rspec

require_relative "../spec_helper"
require "cm/config"
require "tmpdir"

describe Yast::CM::Config do
  subject(:config) { Yast::CM::Config.new(profile) }

  let(:master) { "some-server.suse.com" }
  let(:auth_attempts) { 3 }

  let(:profile) do
    {
      "type"            => "salt",
      "master"          => master,
      "auth_attempts"   => 5,
      "auth_time_out"   => 10,
      "definitions_url" => "http://internal-server.com/definitions.tgz",
      "keys_url"        => "http://internal-server.com/keys.tgz"
    }
  end
  let(:default_path) { Pathname(DATA_DIR).join("cm-salt.yml") }

  before do
    stub_const("Yast::CM::Config::DEFAULT_PATH", default_path)
  end

  describe "#auth_attempts" do
    it "returns the auth_attempts configuration value" do
      expect(config.auth_attempts).to eq(profile["auth_attempts"])
    end

    it "defaults to 3" do
      profile.delete("auth_attempts")
      expect(config.auth_attempts).to eq(3)
    end
  end

  describe "#auth_time_out" do
    it "returns the auth_time_out configuration value" do
      expect(config.auth_time_out).to eq(profile["auth_time_out"])
    end

    it "defaults to 15" do
      profile.delete("auth_time_out")
      expect(config.auth_time_out).to eq(15)
    end
  end

  describe ".load" do
    context "when a path is given" do
      let(:custom_path) { Pathname(DATA_DIR).join("cm-puppet.yml") }

      it "returns the configuration from the given path" do
        expect(YAML).to receive(:load_file).with(custom_path).and_call_original
        config = described_class.load(custom_path)
        expect(config.type).to eq("puppet")
      end
    end

    context "when a path is not given" do
      it "returns the configuration from the default path" do
        expect(YAML).to receive(:load_file).with(default_path).and_call_original
        config = described_class.load
        expect(config.type).to eq("salt")
      end
    end

    context "when the path does not exist" do
      let(:custom_path) { Pathname(DATA_DIR).join("non-existent.yml") }

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
      it "returns :masterless" do
        expect(config.mode).to eq(:client)
      end
    end
  end

  describe "#to_hash" do
    let(:auth_attempts) { nil }

    it "returns a hash with non-nil configuration values" do
      allow(Dir).to receive(:mktmpdir).and_return("/tmp/config-dir")
      expect(config.to_hash).to eq(
        auth_attempts:    profile["auth_attempts"],
        auth_time_out:    profile["auth_time_out"],
        keys_url:         profile["keys_url"],
        type:             profile["type"],
        mode:             :client,
        master:           profile["master"],
        definitions_url:  profile["definitions_url"],
        definitions_root: "/tmp/config-dir"
      )
    end
  end

  describe "#to_secure_hash" do
    it "returns a hash filtering sensible information" do
      allow(Dir).to receive(:mktmpdir).and_return("/tmp/config-dir")
      expect(config.to_secure_hash).to eq(
        auth_attempts:    profile["auth_attempts"],
        auth_time_out:    profile["auth_time_out"],
        type:             profile["type"],
        mode:             :client,
        master:           profile["master"],
        definitions_root: "/tmp/config-dir"
      )
    end
  end

  describe "#write" do
    let(:tmpdir) { Dir.mktmpdir }
    let(:default_path) { Pathname.new(tmpdir).join("default.yml") }

    after(:each) do
      FileUtils.rm_r(tmpdir)
    end

    context "when a path is given" do
      let(:custom_path) { Pathname.new(tmpdir).join("custom.yml") }

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
