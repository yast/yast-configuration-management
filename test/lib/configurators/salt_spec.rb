#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurations/salt"
require "cm/configurators/salt"

describe Yast::CM::Configurators::Salt do
  subject(:configurator) { Yast::CM::Configurators::Salt.new(config) }

  let(:master) { "myserver" }
  let(:states_url) { "https://yast.example.net/myconfig.tgz" }
  let(:work_dir) { "/tmp/config" }
  let(:keys_url) { "https://yast.example.net/keys" }

  let(:config) do
    Yast::CM::Configurations::Salt.new(
      auth_attempts: 3,
      auth_time_out: 10,
      master:        master,
      work_dir:      work_dir,
      states_url:    states_url,
      keys_url:      keys_url
    )
  end

  describe "#packages" do
    context "when running in client mode" do
      it "returns a list containing 'salt' and 'salt-minion' packages" do
        expect(configurator.packages).to eq("install" => ["salt", "salt-minion"])
      end
    end

    context "when running in masterless mode" do
      let(:master) { nil }

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

    context "when running in masterless" do
      let(:master) { nil }
      let(:minion_config) { double("minion", load: true, save: true) }
      let(:key_finder) { double("key_finder", fetch_to: true) }

      before do
        allow(Yast::CM::CFA::Minion).to receive(:new).and_return(minion_config)
        allow(minion_config).to receive(:master=)
        allow(Yast::CM::KeyFinder).to receive(:new).and_return(key_finder)
        allow(configurator).to receive(:fetch_config)
      end

      it "retrieves the Salt states" do
        expect(configurator).to receive(:fetch_config)
          .with(URI(states_url), work_dir)
        configurator.prepare
      end
    end
  end
end