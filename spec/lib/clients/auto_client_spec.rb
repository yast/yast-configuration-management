require_relative "../../spec_helper"
require "scm/clients/auto_client"

describe Yast::SCM::AutoClient do
  subject(:client) { described_class.new }

  let(:provisioner) { double("provisioner", packages: packages) }
  let(:packages) { { "install" => ["pkg1"] } }

  before do
    allow(Yast::SCM::Provisioner).to receive(:new).and_return(provisioner)
    client.import("type" => "salt")
  end

  describe "#packages" do
    context "when provider is 'salt'" do
      it "returns provider list of packages" do
        expect(client.packages).to eq(packages)
      end
    end
  end

  describe "#write" do
    it "delegates writing to current provisioner" do
      expect(provisioner).to receive(:run)
      client.write
    end
  end
end
