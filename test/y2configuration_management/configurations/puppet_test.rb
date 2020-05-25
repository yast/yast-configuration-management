#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/configurations/puppet"
require "tmpdir"

describe Y2ConfigurationManagement::Configurations::Puppet do
  subject(:config) { described_class.new_from_hash(hash) }

  let(:master) { "puppet.suse.de" }
  let(:modules_url) { "http://ftp.suse.de/modules.tgz" }

  let(:hash) do
    {
      "master"      => master,
      "modules_url" => modules_url
    }
  end

  describe "#type" do
    it "returns 'puppet'" do
      expect(config.type).to eq("puppet")
    end
  end
end
