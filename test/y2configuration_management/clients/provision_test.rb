#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/clients/provision"
require "y2configuration_management/configurations/base"

describe Y2ConfigurationManagement::Clients::Provision do
  subject(:client) { described_class.new }

  let(:dialog) { double("dialog") }
  let(:config) { double("config") }
  let(:runner) { double("runner") }

  describe "#run" do
    before do
      allow(Y2ConfigurationManagement::Dialogs::Running).to receive(:new)
        .and_return(dialog)
      allow(Y2ConfigurationManagement::Configurations::Base).to receive(:current)
        .and_return(config)
      allow(Y2ConfigurationManagement::Runners::Base).to receive(:for)
        .and_return(runner)
    end

    it "shows a dialog and runs the runner" do
      expect(dialog).to receive(:run).and_yield($stdout, $stderr)
      expect(runner).to receive(:run)
      client.run
    end
  end
end
