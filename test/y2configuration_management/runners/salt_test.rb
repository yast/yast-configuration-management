#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/runners/salt"
require "y2configuration_management/configurations/salt"

describe Y2ConfigurationManagement::Runners::Salt do
  subject(:runner) { Y2ConfigurationManagement::Runners::Salt.new(config) }
  let(:master) { "salt.suse.de" }
  let(:tmpdir) { "/mnt/tmp/yast_cm" }

  let(:config) do
    Y2ConfigurationManagement::Configurations::Salt.new(
      master: master, log_level: :info
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
      it "runs salt-call" do
        opts = { stdout: $stdout, stderr: $stderr, chroot: "/mnt" }
        expect(Cheetah).to receive(:run).with(
          "salt-call", "--log-level", "info", "state.highstate",
          opts
        )
        expect(runner.run).to eq(true)
      end

      context "when salt-call fails" do
        it "returns false" do
          expect(Cheetah).to receive(:run)
            .with("salt-call", *any_args)
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
          "salt-call", "--log-level", "info", "--local", "state.highstate",
          opts
        )
        expect(runner.run).to eq(true)
      end
    end
  end
end
