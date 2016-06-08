require_relative "../spec_helper"
require "scm/salt_provisioner"
require "yast2/execute"
require "cheetah"

describe Yast::SCM::SaltProvisioner do
  subject(:provisioner) { Yast::SCM::SaltProvisioner.new(config) }
  let(:config) { { "auth_retries" => 3 } }

  before do
    allow(provisioner).to receive(:sleep)
  end
  describe "#packages" do
    it "returns a list containing only 'salt-minion' package" do
      expect(provisioner.packages).to eq("install" => ["salt-minion"])
    end
  end

  describe "#run" do
    let(:minion_config) { double("minion", load: true, save: true) }

    it "runs salt-call" do
      expect(Yast::Execute).to receive(:locally)
        .with("salt-call", "state.highstate")
      expect(provisioner.run)
    end

    context "when salt-call fails" do
      it "retries up to 'auth_times' times" do
        expect(Yast::Execute).to receive(:locally)
          .with("salt-call", "state.highstate").and_raise(Cheetah::ExecutionFailed)
          .exactly(config["auth_retries"]).times
        expect(provisioner.run)
      end
    end

    context "when a master server is specified through the configuration" do
      let(:config) { { "master" => "myserver" } }

      it "updates the configuration file" do
        allow(Yast::SCM::CFA::Minion).to receive(:new).and_return(minion_config)
        expect(minion_config).to receive(:master=).with("myserver")
        provisioner.run
      end
    end

    context "when no master server is specified through the configuration" do
      it "updates the configuration file" do
        expect(Yast::SCM::CFA::Minion).to_not receive(:new)
        provisioner.run
      end
    end
  end
end
