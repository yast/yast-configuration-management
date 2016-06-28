require_relative "../spec_helper"
require "yast2/execute"
require "cm/puppet_provisioner"
require "cheetah"

describe Yast::CM::PuppetProvisioner do
  Yast.import "Hostname"

  subject(:provisioner) { Yast::CM::PuppetProvisioner.new(config) }

  let(:master) { "myserver" }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:keys_url) { "https://yast.example.net/keys" }
  let(:tmpdir) { Pathname.new("tmp") }
  let(:hostname) { "myclient" }

  let(:config) do
    { attempts: 3, timeout: 10, master: master, config_url: config_url, keys_url: keys_url }
  end

  describe "#packages" do
    it "returns a list containing only 'puppet' package" do
      expect(provisioner.packages).to eq("install" => ["puppet"])
    end
  end

  describe "#run" do
    before do
      allow(provisioner).to receive(:config_tmpdir).and_return(tmpdir)
    end

    context "when running in client mode" do
      let(:puppet_config) { double("puppet", load: true, save: true) }
      let(:key_finder) { double("key_finder", fetch_to: true) }

      before do
        allow(Yast::CM::CFA::Puppet).to receive(:new).and_return(puppet_config)
        allow(puppet_config).to receive(:server=)
        allow(Yast::CM::KeyFinder).to receive(:new).and_return(key_finder)
        allow(Yast::Hostname).to receive(:CurrentFQ).and_return(hostname)
      end

      it "runs puppet agent" do
        expect(Yast::Execute).to receive(:locally)
          .with("puppet", "agent", "--onetime", "--no-daemonize",
            "--waitforcert", config[:timeout].to_s)
        expect(provisioner.run).to eq(true)
      end

      context "when puppet agent fails" do
        it "retries up to 'attempts' times" do
          expect(Yast::Execute).to receive(:locally)
            .with("puppet", *any_args).and_raise(Cheetah::ExecutionFailed)
            .exactly(config[:attempts]).times
          expect(provisioner.run).to eq(false)
        end
      end

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("puppet", *any_args)
        expect(puppet_config).to receive(:server=).with(master)
        provisioner.run
      end

      it "retrieves authentication keys" do
        allow(Yast::Execute).to receive(:locally)
          .with(any_args)
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/var/lib/puppet/ssl/private_keys/#{hostname}.pem"),
            Pathname("/var/lib/puppet/ssl/public_keys/#{hostname}.pem"))
        provisioner.run
      end
    end

    context "when running in masterless mode" do
      let(:master) { nil }

      it "runs puppet apply" do
        allow(provisioner).to receive(:fetch_config).and_return(true)
        expect(Yast::Execute).to receive(:locally)
          .with("puppet", "apply", tmpdir.join("manifests", "site.pp").to_s)
        expect(provisioner.run).to eq(true)
      end
    end

    context "when neither master server nor url is specified through the configuration" do
      let(:master) { nil }
      let(:config_url) { nil }

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("puppet", "agent", *any_args)
        expect(Yast::CM::CFA::Puppet).to_not receive(:new)
        provisioner.run
      end
    end
  end
end
