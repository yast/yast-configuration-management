#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurators/puppet"
require "cm/configurations/puppet"

describe Yast::CM::Configurators::Puppet do
  Yast.import "Hostname"

  subject(:configurator) { Yast::CM::Configurators::Puppet.new(config) }

  let(:master) { "myserver" }
  let(:mode) { :client }
  let(:keys_url) { "https://yast.example.net/keys" }
  let(:modules_url) { "https://yast.example.net/myconfig.tgz" }
  let(:work_dir) { "/tmp/config" }
  let(:hostname) { "myclient" }

  let(:config) do
    Yast::CM::Configurations::Puppet.new(
      auth_attempts: 3,
      auth_time_out: 10,
      master:        master,
      work_dir:      work_dir,
      modules_url:   modules_url,
      keys_url:      keys_url
    )
  end

  describe "#packages" do
    it "returns a hash containing only the 'puppet' package" do
      expect(configurator.packages).to eq("install" => ["puppet"])
    end
  end

  describe "#prepare" do
    context "when running in client mode" do
      let(:puppet_config) { double("puppet", load: true, save: true, keys_url: keys_url) }
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

      it "retrieves the authentication keys" do
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/var/lib/puppet/ssl/private_keys/#{hostname}.pem"),
            Pathname("/var/lib/puppet/ssl/public_keys/#{hostname}.pem"))
        configurator.prepare
      end
    end
  end
end
