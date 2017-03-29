#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/cfa/minion_yast_configuration_management"

describe Yast::CM::CFA::MinionYastConfigurationManagement do
  subject(:config) { Yast::CM::CFA::MinionYastConfigurationManagement.new(path: path) }
  let(:path) { FIXTURES_PATH.join("salt", "yast-configuration-management.conf") }

  before do
    config.load
  end

  describe "#set_file_roots" do
    it "sets file_roots for the base environment" do
      config.set_file_roots(["/path1"])
      expect(config.file_roots("base")).to eq(["/path1"])
    end

    context "when an environment is specified" do
      it "sets file_roots for the given environment" do
        old = config.file_roots("base")
        config.set_file_roots(["/path1"], "test")
        expect(config.file_roots("base")).to eq(old)
        expect(config.file_roots("test")).to eq(["/path1"])
      end
    end
  end
end
