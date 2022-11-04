#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/runners/puppet"
require "y2configuration_management/configurations/puppet"

describe Y2ConfigurationManagement::Runners::Puppet do
  subject(:runner) { Y2ConfigurationManagement::Runners::Puppet.new(config) }

  let(:mode) { :masterless }
  let(:log_level) { :notice }
  let(:master) { "puppet.suse.de" }
  let(:tmpdir) { "/mnt/tmp/yast_cm" }

  let(:config) do
    Y2ConfigurationManagement::Configurations::Puppet.new(
      master: master, log_level: log_level
    )
  end

  before do
    allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
  end

  describe "#run" do
    before do
      allow(runner).to receive(:sleep)
      allow(Yast::Installation).to receive(:destdir).and_return("/mnt")
    end

    context "when running in client mode" do
      it "runs puppet agent" do
        opts = { stdout: $stdout, stderr: $stderr, chroot: "/mnt" }
        expect(Cheetah).to receive(:run)
          .with("puppet", "agent", "--onetime", "--no-daemonize",
            "--waitforcert", config.auth_time_out.to_s, opts)
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
        opts = { stdout: $stdout, stderr: $stderr, chroot: "/mnt" }
        expect(Cheetah).to receive(:run).with(
          "puppet", "apply", "--modulepath", config.work_dir.join("modules").to_s,
          config.work_dir.join("manifests", "site.pp").to_s,
          opts
        )
        expect(runner.run).to eq(true)
      end
    end

    context "when log level is set to 'info'" do
      let(:log_level) { :info }

      it "includes the '--verbose' option" do
        expect(Cheetah).to receive(:run) do |*args|
          expect(args).to include("--verbose")
        end
        runner.run
      end
    end

    context "when log level is set to :debug" do
      let(:log_level) { :debug }

      it "includes the '--verbose' and '--debug' options" do
        expect(Cheetah).to receive(:run) do |*args|
          expect(args).to include("--verbose", "--debug")
        end
        runner.run
      end
    end
  end
end
