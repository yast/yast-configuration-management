require_relative "../spec_helper"
require "yast2/execute"
require "scm/puppet_provisioner"
require "cheetah"

describe Yast::SCM::PuppetProvisioner do
  subject(:provisioner) { Yast::SCM::PuppetProvisioner.new(config) }

  let(:master) { "myserver" }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:tmpdir) { Pathname.new("tmp") }

  let(:config) do
    { auth_retries: 3, auth_timeout: 10, master: master, config_url: config_url }
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

      before do
        allow(Yast::SCM::CFA::Puppet).to receive(:new).and_return(puppet_config)
      end

      it "runs puppet agent" do
        allow(puppet_config).to receive(:server=)
        expect(Yast::Execute).to receive(:locally)
          .with("puppet", "agent", "--onetime", "--no-daemonize",
          "--waitforcert", config[:auth_timeout].to_s)
        expect(provisioner.run).to eq(true)
      end

      context "when puppet agent fails" do
        it "retries up to 'auth_retries' times" do
          allow(puppet_config).to receive(:server=)
          expect(Yast::Execute).to receive(:locally)
            .with("puppet", *any_args).and_raise(Cheetah::ExecutionFailed)
            .exactly(config[:auth_retries]).times
          expect(provisioner.run).to eq(false)
        end
      end

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("puppet", *any_args)
        expect(puppet_config).to receive(:server=).with(master)
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
        expect(Yast::SCM::CFA::Puppet).to_not receive(:new)
        provisioner.run
      end
    end
  end
end
