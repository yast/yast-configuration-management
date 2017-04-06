#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/cfa/minion"

describe Yast::ConfigurationManagement::CFA::Minion do
  subject(:config) { Yast::ConfigurationManagement::CFA::Minion.new }

  before do
    stub_const("Yast::ConfigurationManagement::CFA::Minion::PATH",
      FIXTURES_PATH.join("salt", "minion"))
    config.load
  end

  describe "#master" do
    it "returns master server name" do
      expect(config.master).to eq("salt")
    end
  end

  describe "#master=" do
    it "sets the master server name" do
      expect { config.master = "alt" }.to change { config.master }.to("alt")
    end
  end
end
