#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/runners/puppet"

describe Yast::CM::Runners::Puppet do
  subject(:runner) { Yast::CM::Runners::Puppet.new(config) }
  let(:mode) { :masterless }
  let(:tmpdir) { Pathname.new("/tmp/salt") }

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

      it "runs puppet agent" do
        expect(Cheetah).to receive(:run)
          .with("puppet", "agent", "--onetime", "--debug", "--no-daemonize",
            "--waitforcert", config[:auth_time_out].to_s, stdout: $stdout, stderr: $stderr)
        expect(runner.run).to eq(true)
      end

      context "when puppet agent fails" do
        it "retries up to 'auth_attempts' times" do
          expect(Cheetah).to receive(:run)
            .with("puppet", *any_args)
            .and_raise(Cheetah::ExecutionFailed.new([], 0, nil, nil))
            .exactly(config[:auth_attempts]).times
          expect(runner.run).to eq(false)
        end
      end
    end

    context "when running in masterless mode" do
      let(:mode) { :masterless }

      it "runs salt-call" do
        expect(Cheetah).to receive(:run).with(
          "puppet", "apply", "--modulepath", tmpdir.join("modules").to_s,
          tmpdir.join("manifests", "site.pp").to_s, "--debug",
          stdout: $stdout, stderr: $stderr
        )
        expect(runner.run).to eq(true)
      end
    end
  end
end
