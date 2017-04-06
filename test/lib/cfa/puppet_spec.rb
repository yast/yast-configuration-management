#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/cfa/puppet"

describe Yast::ConfigurationManagement::CFA::Puppet do
  subject(:config) { Yast::ConfigurationManagement::CFA::Puppet.new }

  before do
    stub_const("Yast::ConfigurationManagement::CFA::Puppet::PATH",
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
