#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurators/base"
require "cm/key_finder"
require "yast2/execute"

describe Yast::CM::Configurators::Base do
  subject(:configurator) { Yast::CM::Configurators::Base.new(config) }

  let(:master) { "myserver" }
  let(:mode) { :client }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:keys_url) { nil }
  let(:file_from_url_wrapper) { Yast::CM::FileFromUrlWrapper }

  let(:config) do
    { mode: mode, attempts: 3, timeout: 10, master: master, config_url: config_url, keys_url: keys_url }
  end

  describe "#master" do
    it "returns the master option" do
      expect(configurator.master).to eq(config[:master])
    end
  end

  describe "#attempts" do
    it "returns the master option" do
      expect(configurator.attempts).to eq(config[:attempts])
    end
  end

  describe "#timeout" do
    it "returns the timeout option" do
      expect(configurator.timeout).to eq(config[:timeout])
    end
  end

  describe "#packages" do
    it "returns no packages to install/remove" do
      expect(configurator.packages).to eq({})
    end
  end

  describe "#prepare" do
    context "when running in masterless mode" do
      let(:mode) { :masterless }
      let(:fetched_config) { true }

      before do
        allow(configurator).to receive(:fetch_config).and_return(fetched_config)
      end

      it "fetches the configuration" do
        expect(configurator).to receive(:fetch_config)
        configurator.prepare
      end
    end

    context "when running in client mode" do
      before do
        allow(configurator).to receive(:fetch_keys).and_return(true)
      end

      it "fetches the authentication keys" do
        expect(configurator).to receive(:fetch_keys).and_return(true)
        allow(configurator).to receive(:update_configuration).and_return(true)
        configurator.prepare
      end

      it "updates the configuration" do
        expect(configurator).to receive(:update_configuration).and_return(true)
        configurator.prepare
      end

      it "returns true" do
        allow(configurator).to receive(:update_configuration).and_return(true)
        expect(configurator.prepare).to eq(true)
      end

      context "when #update_configuration is not defined" do
        it "raises NotImplementedError" do
          expect { configurator.prepare }.to raise_error(NotImplementedError)
        end
      end
    end

    describe "#fetch_keys" do
      let(:keys_url) { "https://yast.example.net/keys" }
      let(:key_finder) { double("key_finder") }
      let(:public_key_path) { Pathname("/tmp/public") }
      let(:private_key_path) { Pathname("/tmp/private") }

      before do
        allow(configurator).to receive(:public_key_path)
          .and_return(Pathname("/tmp/public"))
        allow(configurator).to receive(:private_key_path)
          .and_return(Pathname("/tmp/private"))
      end

      it "copy keys" do
        expect(Yast::CM::KeyFinder).to receive(:new)
          .with(keys_url: URI(keys_url)).and_return(key_finder)
        expect(key_finder).to receive(:fetch_to)
          .with(private_key_path, public_key_path)
        configurator.fetch_keys
      end
    end

    describe "#fetch_config" do
      let(:tmpdir) { Pathname("/tmp") }

      before do
        allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
      end

      it "downloads and uncompress the configuration to a temporal directory" do
        expect(file_from_url_wrapper).to receive(:get_file)
          .with(URI(config_url), tmpdir.join(Yast::CM::Configurators::Base::CONFIG_LOCAL_FILENAME))
          .and_return(true)
        expect(Yast::Execute).to receive(:locally).with("tar", "xf", *any_args)
          .and_return(true)

        configurator.fetch_config
      end

      context "when the file is downloaded and uncompressed" do
        before do
          allow(file_from_url_wrapper).to receive(:get_file).and_return(true)
          allow(Yast::Execute).to receive(:locally).with("tar", *any_args).and_return(true)
        end

        it "returns true" do
          expect(configurator.fetch_config).to eq(true)
        end
      end

      context "when download fails" do
        before do
          allow(file_from_url_wrapper).to receive(:get_file).and_return(false)
        end

        it "returns false" do
          expect(configurator.fetch_config).to eq(false)
        end
      end

      context "when uncompressing fails" do
        before do
          allow(file_from_url_wrapper).to receive(:get_file).and_return(true)
          allow(Yast::Execute).to receive(:locally).with("tar", *any_args).and_return(false)
        end

        it "returns false" do
          expect(configurator.fetch_config).to eq(false)
        end
      end
    end
  end
end
