#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/cfa/puppet"

describe Y2ConfigurationManagement::CFA::Puppet do
  subject(:config) { Y2ConfigurationManagement::CFA::Puppet.new }

  before do
    stub_const("Y2ConfigurationManagement::CFA::Puppet::PATH",
      FIXTURES_PATH.join("puppet", "puppet.conf"))
    config.load
  end

  describe "#server" do
    it "returns server name" do
      expect(config.server).to eq("master-of-puppets")
    end
  end

  describe "#server" do
    it "sets server name" do
      config.server = "master"
      expect(config.server).to eq("master")
    end
  end
end
