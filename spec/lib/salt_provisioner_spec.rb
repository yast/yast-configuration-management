#!/usr/bin/env rspec

require_relative "../spec_helper"
require "cm/salt_provisioner"
require "yast2/execute"
require "cheetah"

describe Yast::CM::SaltProvisioner do
  subject(:provisioner) { Yast::CM::SaltProvisioner.new(config) }

  let(:master) { "myserver" }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:keys_url) { "https://yast.example.net/keys" }
  let(:tmpdir) { Pathname.new("/tmp") }

  let(:config) do
    { attempts: 3, timeout: 10, master: master, config_url: config_url, keys_url: keys_url }
  end

  before do
    allow(provisioner).to receive(:sleep)
  end

  describe "#packages" do
    it "returns a list containing only 'salt-minion' package" do
      expect(provisioner.packages).to eq("install" => ["salt-minion"])
    end
  end

  describe "#run" do
    before do
      allow(provisioner).to receive(:config_tmpdir).and_return(tmpdir)
    end

    context "when running in client mode" do
      let(:minion_config) { double("minion", load: true, save: true) }
      let(:key_finder) { double("key_finder", fetch_to: true) }

      before do
        allow(Yast::CM::CFA::Minion).to receive(:new).and_return(minion_config)
        allow(minion_config).to receive(:master=)
        allow(Yast::CM::KeyFinder).to receive(:new).and_return(key_finder)
      end

      it "runs salt-call" do
        expect(Yast::Execute).to receive(:locally).with(
          "salt-call", "--log-level", "debug", "state.highstate",
          stdout: $stdout, stderr: $stderr)
        expect(provisioner.run).to eq(true)
      end

      context "when salt-call fails" do
        it "retries up to 'attempts' times" do
          expect(Yast::Execute).to receive(:locally)
            .with("salt-call", *any_args).and_raise(Cheetah::ExecutionFailed)
            .exactly(config[:attempts]).times
          expect(provisioner.run).to eq(false)
        end
      end

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("salt-call", *any_args)
        expect(minion_config).to receive(:master=).with(master)
        provisioner.run
      end

      it "retrieves authentication keys" do
        allow(Yast::Execute).to receive(:locally)
          .with(any_args)
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/etc/salt/pki/minion/minion.pem"),
            Pathname("/etc/salt/pki/minion/minion.pub"))
        provisioner.run
      end
    end

    context "when running in masterless mode" do
      let(:master) { nil }

      it "runs salt-call" do
        allow(provisioner).to receive(:fetch_config).and_return(true)
        expect(Yast::Execute).to receive(:locally).with(
          "salt-call", "--log-level", "debug",
          "--local", "--file-root=#{tmpdir}", "state.highstate",
          stdout: $stdout, stderr: $stderr)
        expect(provisioner.run).to eq(true)
      end
    end

    context "when neither master server nor url is specified through the configuration" do
      let(:master) { nil }
      let(:config_url) { nil }

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("salt-call", *any_args)
        expect(Yast::CM::CFA::Minion).to_not receive(:new)
        provisioner.run
      end
    end
  end
end
