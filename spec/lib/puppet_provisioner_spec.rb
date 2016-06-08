require_relative "../spec_helper"
require "yast2/execute"
require "scm/puppet_provisioner"
require "cheetah"

describe Yast::SCM::PuppetProvisioner do
  subject(:provisioner) { Yast::SCM::PuppetProvisioner.new(config) }

  let(:config) { { auth_retries: 3, auth_timeout: 10 } }

  describe "#packages" do
    it "returns a list containing only 'puppet' package" do
      expect(provisioner.packages).to eq("install" => ["puppet"])
    end
  end

  describe "#run" do
    let(:puppet_config) { double("puppet", load: true, save: true) }

    it "runs puppet agent" do
      expect(Yast::Execute).to receive(:locally)
        .with("puppet", "agent", "--onetime", "--no-daemonize",
          "--waitforcert", config[:auth_timeout].to_s)
      expect(provisioner.run).to eq(true)
    end

    context "when puppet agent fails" do
      it "retries up to 'auth_retries' times" do
        expect(Yast::Execute).to receive(:locally)
          .with("puppet", *any_args).and_raise(Cheetah::ExecutionFailed)
          .exactly(config[:auth_retries]).times
        expect(provisioner.run).to eq(false)
      end
    end

    context "when a master server is specified through the configuration" do
      let(:config) { { master: "myserver" } }

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("puppet", *any_args)
        allow(Yast::SCM::CFA::Puppet).to receive(:new).and_return(puppet_config)
        expect(puppet_config).to receive(:server=).with("myserver")
        provisioner.run
      end
    end

    context "when no master server is specified through the configuration" do
      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("puppet", *any_args)
        expect(Yast::SCM::CFA::Puppet).to_not receive(:new)
        provisioner.run
      end
    end
  end
end
