#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/cfa/salt_top"

describe Yast::ConfigurationManagement::CFA::SaltTop do
  subject(:file) { Yast::ConfigurationManagement::CFA::SaltTop.new(path: path) }
  let(:path) { FIXTURES_PATH.join("salt", "top.sls") }

  describe "#load" do
    context "when file exists" do
      it "reads the configuration" do
        file.load
        expect(file.data).to eq("base" => { "*" => ["motd"] })
      end
    end

    context "when file does not exist" do
      let(:path) { FIXTURES_PATH.join("salt", "non-existent.sls") }

      it "sets the configuration to a empty hash" do
        file.load
        expect(file.data).to eq({})
      end
    end
  end

  describe "#add_states" do
    before { file.load }

    it "adds states to the given environment" do
      file.add_states(["vim"], "base")
      expect(file.states("base")).to eq(["motd", "vim"])
    end

    it "does not duplicate any state" do
      file.add_states(["motd"], "base")
      expect(file.states("base")).to eq(["motd"])
    end

    context "when the file is empty" do
      let(:path) { FIXTURES_PATH.join("salt", "non-existent.sls") }

      it "adds states to the given environment" do
        file.add_states(["emacs"], "base")
        expect(file.states("base")).to eq(["emacs"])
      end
    end
  end
end
