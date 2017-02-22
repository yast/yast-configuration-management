#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/clients/auto_client"
require "cm/configurators/salt"

describe Yast::CM::AutoClient do
  subject(:client) { described_class.new }

  let(:configurator) { double("configurator", packages: packages) }
  let(:packages) { { "install" => ["pkg1"] } }
  let(:profile) { { "type" => "salt", "master" => "myserver" } }
  let(:config) { Yast::CM::Configurations::Base.for(profile) }

  before do
    allow(Yast::CM::Configurations::Base).to receive(:for).with(profile)
      .and_return(config)
    allow(config).to receive(:save)
  end

  describe "#import" do
    it "initializes the current configurator" do
      expect(Yast::CM::Configurators::Base).to receive(:for)
        .with(config).and_call_original
      client.import(profile)
      expect(Yast::CM::Configurators::Base.current).to be_kind_of(Yast::CM::Configurators::Salt)
    end

    it "saves the module configuration to be used after 2nd stage" do
      expect(config).to receive(:save)
      client.import(profile)
    end
  end

  describe "#packages" do
    before do
      expect(Yast::CM::Configurators::Base).to receive(:for)
        .with(config).and_return(configurator)
      client.import(profile)
    end

    it "returns provider list of packages" do
      expect(client.packages).to eq(packages)
    end
  end

  describe "#write" do
    before do
      allow(Yast::CM::Configurators::Base).to receive(:for)
        .with(config).and_return(configurator)
      client.import(profile)
    end

    it "delegates writing to current configurator" do
      expect(configurator).to receive(:prepare)
      client.write
    end
  end

  describe "#export" do
    it "returns an empty hash" do
      expect(client.export).to eq({})
    end
  end

  describe "#modified" do
    it "returns false" do
      expect(client.modified).to eq(false)
    end
  end

  describe "#modified?" do
    it "returns false" do
      expect(client.modified).to eq(false)
    end
  end
end
