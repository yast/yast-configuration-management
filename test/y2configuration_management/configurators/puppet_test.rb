#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/configurators/puppet"
require "y2configuration_management/configurations/puppet"

describe Y2ConfigurationManagement::Configurators::Puppet do
  Yast.import "Hostname"

  subject(:configurator) { Y2ConfigurationManagement::Configurators::Puppet.new(config) }

  let(:master) { "myserver" }
  let(:mode) { :client }
  let(:keys_url) { "https://yast.example.net/keys" }
  let(:modules_url) { "https://yast.example.net/myconfig.tgz" }
  let(:tmpdir) { "/mnt/var/tmp/workdir" }
  let(:work_dir) { "/tmp/config" }
  let(:hostname) { "myclient" }

  let(:config) do
    Y2ConfigurationManagement::Configurations::Puppet.new(
      auth_attempts: 3,
      auth_time_out: 10,
      master:        master,
      modules_url:   modules_url,
      keys_url:      keys_url
    )
  end

  before do
    allow(Yast::Installation).to receive(:destdir).and_return("/mnt")
  end

  describe "#packages" do
    before do
      allow(Yast::Pkg).to receive(:PkgQueryProvides).with("puppet")
        .and_return(candidates)
    end

    context "when a package which provides 'puppet' is found" do
      let(:candidates) { [["puppet-package", :CAND, :NONE]] }

      it "returns a hash containing the package" do
        expect(configurator.packages).to eq("install" => ["puppet-package"])
      end
    end

    context "when a package which provides 'puppet' is not found" do
      let(:candidates) { [] }

      it "returns an empty hash" do
        expect(configurator.packages).to eq({})
      end
    end
  end

  describe "#prepare" do
    let(:puppet_config) { double("puppet", load: true, save: true, keys_url: keys_url) }
    let(:key_finder) { double("key_finder", fetch_to: true) }

    before do
      allow(Y2ConfigurationManagement::CFA::Puppet).to receive(:new).and_return(puppet_config)
      allow(puppet_config).to receive(:server=)
      allow(Yast::Hostname).to receive(:CurrentFQ).and_return(hostname)
      allow(FileUtils).to receive(:mkdir_p)
    end

    context "when running in client mode" do
      before do
        allow(Y2ConfigurationManagement::KeyFinder).to receive(:new).and_return(key_finder)
      end

      it "updates the configuration file" do
        expect(puppet_config).to receive(:server=).with(master)
        configurator.prepare
      end

      it "retrieves the authentication keys" do
        expect(key_finder).to receive(:fetch_to)
          .with(Pathname("/mnt/var/lib/puppet/ssl/private_keys/#{hostname}.pem"),
            Pathname("/mnt/var/lib/puppet/ssl/public_keys/#{hostname}.pem"))
        configurator.prepare
      end
    end

    context "when running in masterless" do
      let(:master) { nil }

      before do
        allow(configurator).to receive(:fetch_config)
      end

      it "retrieves the Puppet modules" do
        expect(configurator).to receive(:fetch_config)
          .with(URI(modules_url), configurator.target_path(config.work_dir))
        configurator.prepare
      end
    end
  end
end
