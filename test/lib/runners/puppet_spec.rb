#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/runners/puppet"
require "configuration_management/configurations/puppet"

describe Yast::ConfigurationManagement::Runners::Puppet do
  subject(:runner) { Yast::ConfigurationManagement::Runners::Puppet.new(config) }

  let(:mode) { :masterless }
  let(:master) { "puppet.suse.de" }
  let(:work_dir) { config.work_dir }

  let(:config) do
    Yast::ConfigurationManagement::Configurations::Puppet.new(master: master)
  end

  describe "#run" do
    before do
      allow(runner).to receive(:sleep)
      allow(Yast::Installation).to receive(:destdir).and_return("/mnt")
    end

    context "when running in client mode" do
      it "runs puppet agent" do
        expect(Cheetah).to receive(:run)
          .with("puppet", "agent", "--onetime", "--debug", "--no-daemonize",
            "--waitforcert", config.auth_time_out.to_s, stdout: $stdout,
            stderr: $stderr, chroot: "/mnt")
        expect(runner.run).to eq(true)
      end

      context "when puppet agent fails" do
        it "retries up to 'auth_attempts' times" do
          expect(Cheetah).to receive(:run)
            .with("puppet", *any_args)
            .and_raise(Cheetah::ExecutionFailed.new([], 0, nil, nil))
            .exactly(config.auth_attempts).times
          expect(runner.run).to eq(false)
        end
      end
    end

    context "when running in masterless mode" do
      let(:master) { nil }

      it "runs salt-call" do
        expect(Cheetah).to receive(:run).with(
          "puppet", "apply", "--modulepath", work_dir.join("modules").to_s,
          work_dir.join("manifests", "site.pp").to_s, "--debug",
          stdout: $stdout, stderr: $stderr, chroot: "/mnt"
        )
        expect(runner.run).to eq(true)
      end
    end
  end
end
