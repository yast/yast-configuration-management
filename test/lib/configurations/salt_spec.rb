#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/configurations/salt"
require "tmpdir"

describe Yast::CM::Configurations::Salt do
  subject(:config) { Yast::CM::Configurations::Salt.new(profile) }

  let(:master) { "puppet.suse.de" }
  let(:states_url) { "http://ftp.suse.de/modules.tgz" }

  let(:profile) do
    {
      master:     master,
      states_url: URI(states_url)
    }
  end

  describe "#type" do
    it "returns 'salt'" do
      expect(config.type).to eq("salt")
    end
  end

  describe "given a configuration" do
    it { is_expected.to have_attributes(states_url: URI(states_url)) }
  end

  describe "#to_hash" do
    it "returns configuration values" do
      expect(config.to_hash).to include(
        master: master, states_url: URI(states_url)
      )
    end

    context "when some values are nil" do
      let(:master) { nil }

      it "those values are not included" do
        expect(config.to_hash.keys).to_not include(:master)
      end
    end
  end

  describe "#states_root" do
    it "returns work_dir + 'salt'" do
      expect(config.states_root).to eq(config.work_dir.join("salt"))
    end
  end

  describe "#pillar_root" do
    it "returns work_dir + 'pillar'" do
      expect(config.pillar_root).to eq(config.work_dir.join("pillar"))
    end
  end
end
