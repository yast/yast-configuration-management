#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/runners/salt"

describe Yast::CM::Runners::Salt do
  subject(:runner) { Yast::CM::Runners::Salt.new(config) }
  let(:master) { "salt.suse.de" }
  let(:work_dir) { config.work_dir }

  let(:config) do
    Yast::CM::Configurations::Puppet.new(master: master)
  end

  describe "#run" do
    before do
      allow(runner).to receive(:sleep)
    end

    context "when running in client mode" do
      it "runs salt-call" do
        expect(Cheetah).to receive(:run).with(
          "salt-call", "--log-level", "debug", "state.highstate",
          stdout: $stdout, stderr: $stderr
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
        expect(Cheetah).to receive(:run).with(
          "salt-call", "--log-level", "debug",
          "--local", "--file-root=#{work_dir}", "state.highstate",
          stdout: $stdout, stderr: $stderr
        )
        expect(runner.run).to eq(true)
      end
    end
  end
end
