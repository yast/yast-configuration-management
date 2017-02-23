#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/cfa/simple_minion"

describe Yast::CM::CFA::SimpleMinion do
  subject(:config) { Yast::CM::CFA::SimpleMinion.new(path: path) }
  let(:path) { FIXTURES_PATH.join("salt", "minion") }

  before do
    stub_const("Yast::CM::CFA::Minion::PATH", FIXTURES_PATH.join("salt", "minion"))
    config.load
  end

  describe "#set_file_roots" do
    it "sets file_roots for the base environment" do
      config.set_file_roots(["/path1"])
      expect(config.file_roots("base")).to eq(["/path1"])
    end

    context "when an environment is specified" do
      it "sets file_roots for the given environment" do
        config.set_file_roots(["/path1"], "test")
        expect(config.file_roots("base")).to be_empty
        expect(config.file_roots("test")).to eq(["/path1"])
      end
    end
  end
end
