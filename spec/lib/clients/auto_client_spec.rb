#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/clients/auto_client"
require "cm/configurators/salt"

describe Yast::CM::AutoClient do
  subject(:client) { described_class.new }

  let(:configurator) { double("configurator", packages: packages) }
  let(:packages) { { "install" => ["pkg1"] } }
  let(:profile) { { "type" => "salt", "master" => "myserver" } }

  describe "#import" do
    it "initializes the current configurator" do
      expect(Yast::CM::Configurators::Base).to receive(:configurator_for)
        .with(profile["type"], master: "myserver")
        .and_call_original
      client.import(profile)
      expect(Yast::CM::Configurators::Base.current).to be_kind_of(Yast::CM::Configurators::Salt)
    end
  end

  describe "#packages" do
    before do
      expect(Yast::CM::Configurators::Base).to receive(:configurator_for)
        .with(profile["type"], master: "myserver")
        .and_return(configurator)
      client.import(profile)
    end

    it "returns provider list of packages" do
      expect(client.packages).to eq(packages)
    end
  end

  describe "#write" do
    before do
      allow(Yast::CM::Configurators::Base).to receive(:configurator_for)
        .with(profile["type"], any_args)
        .and_return(configurator)
      client.import(profile)
    end

    it "delegates writing to current configurator" do
      expect(Yast::UI).to receive(:TimeoutUserInput).and_return(:ok)
      expect(configurator).to receive(:run)
      client.write
    end
  end
end
