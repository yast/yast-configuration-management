#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/cfa/minion_file_roots_config"

describe Yast::CM::CFA::MinionFileRootsConfig do
  subject(:config) { Yast::CM::CFA::MinionFileRootsConfig.new(path: path) }
  let(:path) { FIXTURES_PATH.join("salt", "file_roots.conf") }

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
