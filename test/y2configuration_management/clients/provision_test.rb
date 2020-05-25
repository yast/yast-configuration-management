#!/usr/bin/env rspec

require_relative "../../spec_helper"
require "y2configuration_management/clients/provision"
require "y2configuration_management/configurations/base"

describe Y2ConfigurationManagement::Clients::Provision do
  subject(:client) { described_class.new }

  let(:dialog) { double("dialog", run: nil) }
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

    context "during autoinstallation" do
      let(:messages_settings) do
        { "show" => true, "timeout" => 10 }
      end

      let(:errors_settings) do
        { "show" => true, "timeout" => 30 }
      end

      before do
        Yast::Report.Import("messages" => messages_settings, "errors" => errors_settings)
      end

      around do |example|
        old_mode = Yast::Mode.mode
        Yast::Mode.SetMode("autoinstallation")
        example.run
        Yast::Mode.SetMode(old_mode)
      end

      it "sets show/timeout settings from Yast::Report" do
        expect(Y2ConfigurationManagement::Dialogs::Running).to receive(:new)
          .with(
            reporting_opts: {
              open_after_success: true, open_after_error: true,
              timeout_after_success: 10, timeout_after_error: 30
            }
          ).and_return(dialog)
        client.run
      end
    end

    context "during normal mode" do
      it "shows all messages and errors" do
        expect(Y2ConfigurationManagement::Dialogs::Running).to receive(:new)
          .with(reporting_opts: { open_after_success: true, open_after_error: true })
          .and_return(dialog)
        client.run
      end
    end
  end
end
