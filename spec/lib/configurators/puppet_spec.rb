#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurators/puppet"

describe Yast::CM::Configurators::Puppet do
  Yast.import "Hostname"

  subject(:configurator) { Yast::CM::Configurators::Puppet.new(config) }

  let(:master) { "myserver" }
  let(:mode) { :client }
  let(:config_url) { "https://yast.example.net/myconfig.tgz" }
  let(:config_dir) { "/tmp/config" }
  let(:keys_url) { "https://yast.example.net/keys" }
  let(:hostname) { "myclient" }

  let(:config) do
    { mode: mode, attempts: 3, timeout: 10, master: master,
      config_url: config_url, config_dir: config_dir, keys_url: keys_url }
  end

  describe "#packages" do
    it "returns a list containing only 'puppet' package" do
      expect(configurator.packages).to eq("install" => ["puppet"])
    end
  end

  describe "#prepare" do
    context "when running in client mode" do
      let(:puppet_config) { double("puppet", load: true, save: true) }
      let(:key_finder) { double("key_finder", fetch_to: true) }

      before do
        allow(Yast::CM::CFA::Puppet).to receive(:new).and_return(puppet_config)
        allow(puppet_config).to receive(:server=)
        allow(Yast::CM::KeyFinder).to receive(:new).and_return(key_finder)
        allow(Yast::Hostname).to receive(:CurrentFQ).and_return(hostname)
      end

      it "updates the configuration file" do
        expect(puppet_config).to receive(:server=).with(master)
        configurator.prepare
      end

      it "retrieves authentication keys" do
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/var/lib/puppet/ssl/private_keys/#{hostname}.pem"),
            Pathname("/var/lib/puppet/ssl/public_keys/#{hostname}.pem"))
        configurator.prepare
      end
    end
  end
end
