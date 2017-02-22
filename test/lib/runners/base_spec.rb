#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/runners/base"

describe Yast::CM::Runners::Base do
  subject(:runner) { Yast::CM::Runners::Base.new(config) }
  let(:mode) { :masterless }

  let(:config) { double("config", master: "salt.suse.de", mode: mode) }

  describe ".for" do
    context "when type is unknown" do
      before do
        allow(config).to receive(:type).and_return("unknown")
      end

      it "raises an error" do
        expect { Yast::CM::Runners::Base.for(config) }.to raise_error
      end
    end
  end

  describe "#run" do
    context "when a known mode is specified" do
      let(:mode) { :masterless }

      it "raises a NotImplementedError error" do
        expect { runner.run }.to raise_error(NotImplementedError)
      end
    end

    context "when a unknown mode is specified" do
      let(:mode) { :unknown }

      it "raises a" do
        expect { runner.run }.to raise_error(NoMethodError)
      end
    end
  end
end
