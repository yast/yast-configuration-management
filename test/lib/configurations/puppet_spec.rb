#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/configurations/puppet"
require "tmpdir"

describe Yast::ConfigurationManagement::Configurations::Puppet do
  subject(:config) { Yast::ConfigurationManagement::Configurations::Puppet.new(profile) }

  let(:master) { "puppet.suse.de" }
  let(:modules_url) { "http://ftp.suse.de/modules.tgz" }

  let(:profile) do
    {
      master:      master,
      modules_url: modules_url
    }
  end

  describe "#type" do
    it "returns 'puppet'" do
      expect(config.type).to eq("puppet")
    end
  end

  describe "given a configuration" do
    it { is_expected.to have_attributes(modules_url: URI(modules_url)) }
  end

  describe "#to_hash" do
    it "returns configuration values" do
      expect(config.to_hash).to include(
        master: master, modules_url: URI(modules_url)
      )
    end

    context "when some values are nil" do
      let(:master) { nil }

      it "those values are not included" do
        expect(config.to_hash.keys).to_not include(:master)
      end
    end
  end
end
