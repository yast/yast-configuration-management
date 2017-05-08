#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/runners/base"

describe Yast::ConfigurationManagement::Runners::Base do
  subject(:runner) { Yast::ConfigurationManagement::Runners::Base.new(config) }
  let(:mode) { :masterless }

  let(:config) { double("config", master: "salt.suse.de", mode: mode, type: "salt") }

  describe ".for" do
    it "returns a runner for the given configuration" do
      runner = described_class.for(config)
      expect(runner).to be_kind_of(Yast::ConfigurationManagement::Runners::Salt)
      expect(runner.config).to eq(config)
    end

    context "when type is unknown" do
      before do
        allow(config).to receive(:type).and_return("unknown")
      end

      it "raises an error" do
        expect { Yast::ConfigurationManagement::Runners::Base.for(config) }.to raise_error
      end
    end
  end

  describe "#run" do
    let(:zypp_pid) { described_class.const_get("ZYPP_PID") }
    let(:zypp_pid_backup) { described_class.const_get("ZYPP_PID_BACKUP") }

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

    context "when zypp is locked" do
      before do
        allow(zypp_pid).to receive(:exist?).and_return(true)
        allow(zypp_pid_backup).to receive(:exist?).and_return(true)
        allow(runner).to receive(:run_masterless_mode)
      end

      it "moves and restores the zypp lock" do
        expect(::FileUtils).to receive(:mv).with(zypp_pid, zypp_pid_backup)
        expect(::FileUtils).to receive(:mv).with(zypp_pid_backup, zypp_pid)
        runner.run
      end
    end
  end
end
