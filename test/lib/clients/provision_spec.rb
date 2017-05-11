#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "configuration_management/clients/provision"
require "configuration_management/configurations/base"

describe Yast::ConfigurationManagement::Clients::Provision do
  subject(:client) { described_class.new }

  let(:dialog) { double("dialog") }
  let(:config) { double("config") }
  let(:runner) { double("runner") }

  describe "#run" do
    before do
      allow(Yast::ConfigurationManagement::Dialogs::Running).to receive(:new)
        .and_return(dialog)
      allow(Yast::ConfigurationManagement::Configurations::Base).to receive(:current)
        .and_return(config)
      allow(Yast::ConfigurationManagement::Runners::Base).to receive(:for)
        .and_return(runner)
    end

    it "shows a dialog and runs the runner" do
      expect(dialog).to receive(:run).and_yield($stdout, $stderr)
      expect(runner).to receive(:run)
      client.run
    end
  end
end
