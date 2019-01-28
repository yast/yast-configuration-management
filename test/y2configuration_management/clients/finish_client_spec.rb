#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/clients/configuration_management_finish"

describe Y2ConfigurationManagement::ConfigurationManagementFinish do
  subject(:client) { described_class.new }

  describe "#write" do
    let(:configurator) { double("configurator", prepare: true, services: ["salt-minion"]) }
    let(:provision_client) { double("provision_client", run: true) }

    before do
      allow(Y2ConfigurationManagement::Configurations::Base).to receive(:current)
        .and_return(config)
      allow(Y2ConfigurationManagement::Configurators::Base).to receive(:current)
        .and_return(configurator)
      allow(Y2ConfigurationManagement::Clients::Provision).to receive(:new)
        .and_return(provision_client)
    end

    context "when not configuration is set" do
      let(:config) { nil }

      it "does not run the provisioner" do
        expect(provision_client).to_not receive(:run)
      end

      it "returns false" do
        expect(client.write).to eq(false)
      end
    end

    context "when configuration is set" do
      let(:config) { double("config", enable_services: false) }

      it "runs the configurator" do
        expect(configurator).to receive(:prepare)
        client.write
      end

      it "runs the provisioner" do
        expect(provision_client).to receive(:run)
        client.write
      end

      it "returns true" do
        expect(client.write).to eq(true)
      end
    end

    context "when 'enable_services' option is set to true" do
      let(:config) { double("config", enable_services: true) }

      it "tries to enable services" do
        expect(Yast::Service).to receive(:Enable).with("salt-minion")
        client.write
      end
    end
  end
end
