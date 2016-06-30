require_relative "../../spec_helper"
require "cm/clients/auto_client"
require "cm/salt_provisioner"

describe Yast::CM::AutoClient do
  subject(:client) { described_class.new }

  let(:provisioner) { double("provisioner", packages: packages) }
  let(:packages) { { "install" => ["pkg1"] } }
  let(:profile) { { "type" => "salt", "master" => "myserver" } }

  describe "#import" do
    it "initializes the current provisioner" do
      expect(Yast::CM::Provisioner).to receive(:provisioner_for)
        .with(profile["type"], master: "myserver")
        .and_call_original
      client.import(profile)
      expect(Yast::CM::Provisioner.current).to be_kind_of(Yast::CM::SaltProvisioner)
    end
  end

  describe "#packages" do
    before do
      expect(Yast::CM::Provisioner).to receive(:provisioner_for)
        .with(profile["type"], master: "myserver")
        .and_return(provisioner)
      client.import(profile)
    end

    it "returns provider list of packages" do
      expect(client.packages).to eq(packages)
    end
  end

  describe "#write" do
    before do
      allow(Yast::CM::Provisioner).to receive(:provisioner_for)
        .with(profile["type"], any_args)
        .and_return(provisioner)
      client.import(profile)
    end

    it "delegates writing to current provisioner" do
      expect(Yast::UI).to receive(:TimeoutUserInput).and_return(:ok)
      expect(provisioner).to receive(:run)
      client.write
    end
  end
end
