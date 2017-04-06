#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/clients/provision"
require "configuration_management/configurations/base"

describe Yast::ConfigurationManagement::Clients::Provision do
  subject(:client) { described_class.new }
  let(:dialog) do
    double("dialog")
  end

  describe "#run" do
    before do
      stub_const("Yast::ConfigurationManagement::Configurations::Base::DEFAULT_PATH",
        FIXTURES_PATH.join("cm-salt.yml"))
      allow(Yast::ConfigurationManagement::Dialogs::Running).to receive(:new)
        .and_return(dialog)
    end

    it "runs" do
      expect(dialog).to receive(:run).and_yield($stdout, $stderr)
      expect_any_instance_of(Yast::ConfigurationManagement::Runners::Salt).to receive(:run)
      client.run
    end
  end
end
