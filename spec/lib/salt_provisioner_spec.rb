require_relative "../spec_helper"
require "scm/salt_provisioner"
require "yast2/execute"
require "cheetah"

describe Yast::SCM::SaltProvisioner do
  subject(:provisioner) { Yast::SCM::SaltProvisioner.new(config) }

  let(:master) { "myserver" }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:tmpdir) { Pathname.new("/tmp") }

  let(:config) do
    { attempts: 3, timeout: 10, master: master, config_url: config_url }
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

      before do
        allow(Yast::SCM::CFA::Minion).to receive(:new).and_return(minion_config)
        allow(minion_config).to receive(:master=)
      end

      it "runs salt-call" do
        expect(Yast::Execute).to receive(:locally)
          .with("salt-call", "state.highstate")
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
    end

    context "when running in masterless mode" do
      let(:master) { nil }

      it "runs salt-call" do
        allow(provisioner).to receive(:fetch_config).and_return(true)
        expect(Yast::Execute).to receive(:locally)
          .with("salt-call", "--local", "--file-root=#{tmpdir}", "state.highstate")
        expect(provisioner.run).to eq(true)
      end
    end

    context "when neither master server nor url is specified through the configuration" do
      let(:master) { nil }
      let(:config_url) { nil }

      it "updates the configuration file" do
        allow(Yast::Execute).to receive(:locally)
          .with("salt-call", *any_args)
        expect(Yast::SCM::CFA::Minion).to_not receive(:new)
        provisioner.run
      end
    end
  end
end
