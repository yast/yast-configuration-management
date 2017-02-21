#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/runners/salt"

describe Yast::CM::Runners::Salt do
  subject(:runner) { Yast::CM::Runners::Salt.new(config) }
  let(:mode) { :masterless }
  let(:tmpdir) { "/tmp/salt" }

  let(:config) do
    { auth_attempts: 3, auth_time_out: 10, master: "some-server.suse.com",
      mode: mode, definitions_root: tmpdir }
  end

  describe "#run" do
    before do
      allow(runner).to receive(:sleep)
    end

    context "when running in client mode" do
      let(:mode) { :client }

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
          expect(runner.run).to eq(false)
        end
      end
    end

    context "when running in masterless mode" do
      let(:mode) { :masterless }

      it "runs salt-call" do
        expect(Cheetah).to receive(:run).with(
          "salt-call", "--log-level", "debug",
          "--local", "--file-root=#{tmpdir}", "state.highstate",
          stdout: $stdout, stderr: $stderr
        )
        expect(runner.run).to eq(true)
      end
    end
  end
end
