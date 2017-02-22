#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurators/salt"

describe Yast::CM::Configurators::Salt do
  subject(:configurator) { Yast::CM::Configurators::Salt.new(config) }

  let(:master) { "myserver" }
  let(:mode) { :client }
  let(:definitions_url) { "https://yast.example.net/myconfig.tgz" }
  let(:definitions_root) { "/tmp/config" }
  let(:keys_url) { "https://yast.example.net/keys" }

  let(:config) do
    { mode: mode, auth_attempts: 3, auth_time_out: 10, master: master,
      definitions_root: definitions_root, definitions_url: definitions_url, keys_url: keys_url }
  end

  describe "#packages" do
    context "when running in client mode" do
      it "returns a list containing 'salt' and 'salt-minion' packages" do
        expect(configurator.packages).to eq("install" => ["salt", "salt-minion"])
      end
    end

    context "when running in masterless mode" do
      let(:mode) { :masterless }

      it "returns a list containing only the 'salt' package" do
        expect(configurator.packages).to eq("install" => ["salt"])
      end
    end
  end

  describe "#prepare" do
    context "when running in client mode" do
      let(:minion_config) { double("minion", load: true, save: true) }
      let(:key_finder) { double("key_finder", fetch_to: true) }

      before do
        allow(Yast::CM::CFA::Minion).to receive(:new).and_return(minion_config)
        allow(minion_config).to receive(:master=)
        allow(Yast::CM::KeyFinder).to receive(:new).and_return(key_finder)
      end

      it "updates the configuration file" do
        expect(minion_config).to receive(:master=).with(master)
        configurator.prepare
      end

      it "retrieves authentication keys" do
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/etc/salt/pki/minion/minion.pem"),
            Pathname("/etc/salt/pki/minion/minion.pub"))
        configurator.prepare
      end
    end
  end
end
