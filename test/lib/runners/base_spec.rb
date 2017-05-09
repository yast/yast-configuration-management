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
        expect { Yast::ConfigurationManagement::Runners::Base.for(config) }
          .to raise_error(Yast::ConfigurationManagement::Runners::UnknownRunner)
      end
    end
  end

  describe "#run" do
    let(:zypp_pid) { Pathname.new("/mnt/var/run/zypp.pid") }
    let(:zypp_pid_backup) { Pathname.new("/mnt/var/run/zypp.save") }

    before do
      allow(Yast::Installation).to receive(:destdir).and_return("/mnt")
      allow(File).to receive(:exist?).and_call_original
    end

    context "when a known mode is specified" do
      let(:mode) { :masterless }

      it "tries to run the mode" do
        expect(runner).to receive(:run_masterless_mode)
        runner.run
      end

      it "raises a NotImplementedError error" do
        expect { runner.run }.to raise_error(NotImplementedError)
      end
    end

    context "when a unknown mode is specified" do
      let(:mode) { :unknown }

      it "raises a NotMethodError" do
        expect { runner.run }.to raise_error(NoMethodError)
      end
    end

    context "when zypp is locked" do
      before do
        allow(File).to receive(:exist?).with(zypp_pid).and_return(true)
        allow(File).to receive(:exist?).with(zypp_pid_backup).and_return(false, true)
        allow(runner).to receive(:run_masterless_mode)
      end

      it "backups/restores the zypp lock" do
        expect(FileUtils).to receive(:mv).with(zypp_pid, zypp_pid_backup)
        expect(FileUtils).to receive(:mv).with(zypp_pid_backup, zypp_pid)
        runner.run
      end

      it "tries to run the mode" do
        allow(FileUtils).to receive(:mv)
        expect(runner).to receive(:run_masterless_mode)
        runner.run
      end
    end

    context "when zypp is already temporarily unlocked" do
      before do
        allow(File).to receive(:exist?).with(zypp_pid_backup).and_return(true)
      end

      it "raises an exception" do
        expect { runner.run }
          .to raise_error(Yast::ConfigurationManagement::Runners::Base::WithoutZyppLockNotAllowed)
      end
    end

    context "when zypp is not locked" do
      before do
        allow(File).to receive(:exist?).with(zypp_pid).and_return(false)
        allow(File).to receive(:exist?).with(zypp_pid_backup).and_return(false)
        allow(runner).to receive(:run_masterless_mode)
      end

      it "does not try to backup/restore the zypp lock" do
        expect(FileUtils).to_not receive(:mv)
        runner.run
      end

      it "tries to run the mode" do
        allow(FileUtils).to receive(:mv)
        expect(runner).to receive(:run_masterless_mode)
        runner.run
      end
    end
  end
end
