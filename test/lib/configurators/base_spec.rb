#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/configurators/base"
require "configuration_management/configurations/salt"

describe Yast::ConfigurationManagement::Configurators::Base do
  subject(:configurator) { Yast::ConfigurationManagement::Configurators::Base.new(config) }

  let(:master) { "myserver" }
  let(:mode) { :client }
  let(:keys_url) { nil }
  let(:states_url) { "https://yast.example.net/myconfig.tgz" }
  let(:work_dir) { FIXTURES_PATH.join("tmp") }
  let(:file_from_url_wrapper) { Yast::ConfigurationManagement::FileFromUrlWrapper }

  let(:config) do
    Yast::ConfigurationManagement::Configurations::Salt.new(
      auth_attempts: 3,
      auth_time_out: 10,
      master:        master,
      states_url:    states_url,
      keys_url:      keys_url
    )
  end

  # Dummy configurator
  class DummyClass < Yast::ConfigurationManagement::Configurators::Base
    mode(:client) { 1 }
  end

  describe ".mode" do
    it "defines a method 'prepare_MODE'" do
      configurator = DummyClass.new({})
      expect(configurator.prepare_client).to eq(1)
    end
  end

  describe "#packages" do
    it "returns no packages to install/remove" do
      expect(configurator.packages).to eq({})
    end
  end

  describe "#prepare" do
    before do
      allow(config).to receive(:work_dir).and_return(work_dir)
      allow(FileUtils).to receive(:mkdir_p)
      allow(configurator).to receive(:send).with("prepare_client")
    end

    it "calls to 'prepare_MODE' method" do
      expect(configurator).to receive(:send).with("prepare_client")
      configurator.prepare
    end

    context "when running in masterless mode" do
      let(:master) { nil }

      before do
        allow(configurator).to receive(:send).with("prepare_masterless")
      end

      it "creates the work_dir" do
        expect(FileUtils).to receive(:mkdir_p).with(config.work_dir)
        configurator.prepare
      end
    end

    context "when running in client mode" do
      it "does not create the work_dir" do
        expect(FileUtils).to_not receive(:mkdir_p)
        configurator.prepare
      end
    end
  end

  describe "#fetch_keys" do
    let(:url) { URI("https://yast.example.net/keys") }
    let(:key_finder) { double("key_finder") }
    let(:public_key_path) { Pathname("/tmp/public") }
    let(:private_key_path) { Pathname("/tmp/private") }

    it "retrieves the authentication keys" do
      expect(Yast::ConfigurationManagement::KeyFinder).to receive(:new)
        .with(keys_url: url).and_return(key_finder)
      expect(key_finder).to receive(:fetch_to)
        .with(private_key_path, public_key_path)
      configurator.fetch_keys(url, private_key_path, public_key_path)
    end
  end

  describe "#fetch_config" do
    let(:url) { "http://yast.example.net/config.tgz" }
    let(:target) { FIXTURES_PATH.join("tmp") }

    it "downloads and uncompress the configuration to a temporal directory" do
      expect(file_from_url_wrapper).to receive(:get_file)
        .with(url, target.join(described_class.const_get("CONFIG_LOCAL_FILENAME")))
        .and_return(true)
      expect(Yast::Execute).to receive(:locally).with("tar", "xf", *any_args)
        .and_return(true)

      configurator.fetch_config(url, target)
    end

    context "when the file is downloaded and uncompressed" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file).and_return(true)
        allow(Yast::Execute).to receive(:locally).with("tar", *any_args).and_return(true)
      end

      it "returns true" do
        expect(configurator.fetch_config(url, target)).to eq(true)
      end
    end

    context "when download fails" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file).and_return(false)
      end

      it "returns false" do
        expect(configurator.fetch_config(url, target)).to eq(false)
      end
    end

    context "when uncompressing fails" do
      before do
        allow(file_from_url_wrapper).to receive(:get_file).and_return(true)
        allow(Yast::Execute).to receive(:locally).with("tar", *any_args).and_return(false)
      end

      it "returns false" do
        expect(configurator.fetch_config(url, target)).to eq(false)
      end
    end
  end
end
