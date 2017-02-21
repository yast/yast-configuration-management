#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/runners/base"

describe Yast::CM::Runners::Base do
  subject(:runner) { Yast::CM::Runners::Base.new(config) }
  let(:mode) { :masterless }

  let(:config) do
    { auth_attempts: 3, auth_time_out: 10, master: "some-server.suse.com", mode: mode }
  end

  describe "#run" do
    context "when running in masterless mode" do
      let(:mode) { :masterless }

      it "runs run_masterless_mode if defined" do
        allow(runner).to receive(:run_masterless_mode).and_return(true)
        runner.run
      end

      it "raises NotImplementedError" do
        expect { runner.run }.to raise_error(NotImplementedError)
      end
    end

    context "when running in client mode" do
      let(:mode) { :client }

      it "runs run_client_mode if defined" do
        allow(runner).to receive(:run_client_mode).and_return(true)
        runner.run
      end

      it "raises NotImplementedError" do
        expect { runner.run }.to raise_error(NotImplementedError)
      end
    end
  end
end
