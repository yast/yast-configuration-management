#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "cm/runners/base"

describe Yast::CM::Runners::Base do
  subject(:runner) { Yast::CM::Runners::Base.new(config) }

  let(:config) do
    { auth_attempts: 3, auth_time_out: 10, master: "some-server.suse.com", mode: mode }
  end

  describe "#run" do
    let(:mode) { :masterless }

    context "when a known mode is specified" do
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
