#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../spec_helper"
require "y2configuration_management/clients/main"

describe Y2ConfigurationManagement::Clients::Main do
  subject(:main) { described_class.new }

  describe "#run" do
    let(:prepared) { true }
    let(:config) do
      { "configuration_management" =>  { "type" => "salt" } }
    end
    let(:filename) { "config.xml" }
    let(:file_exists?) { true }
    let(:provision) { instance_double(Y2ConfigurationManagement::Clients::Provision, run: nil) }
    let(:packages) { { "install" => ["salt"] } }
    let(:configurator) do
      instance_double(
        Y2ConfigurationManagement::Configurators::Salt, prepare: prepared, packages: packages
      )
    end
    let(:configuration) { Y2ConfigurationManagement::Configurations::Base }

    before do
      allow(Yast::WFM).to receive(:Args).with(0).and_return(filename)
      allow(Yast::XML).to receive(:XMLToYCPFile).with(filename).and_return(config)
      allow(Y2ConfigurationManagement::Configurators::Base).to receive(:for)
        .and_return(configurator)
      allow(Y2ConfigurationManagement::Clients::Provision).to receive(:new)
        .and_return(provision)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(filename).and_return(file_exists?)
      allow(Yast::PackageSystem).to receive(:CheckAndInstallPackages).and_return(true)
      allow(provision).to receive(:run)
    end

    context "when the configuration file is not found" do
      let(:file_exists?) { false }

      it "uses the default_settings" do
        expect(configuration).to receive(:for)
          .with(described_class::DEFAULT_SETTINGS).and_call_original

        main.run
      end
    end

    context "when no filename is given" do
      let(:filename) { nil }

      it "uses the default_settings" do
        expect(configuration).to receive(:for)
          .with(described_class::DEFAULT_SETTINGS).and_call_original

        main.run
      end
    end

    context "when no valid configuration is given" do
      let(:config) { nil }

      it "uses the default_settings" do
        expect(configuration).to receive(:for)
          .with(described_class::DEFAULT_SETTINGS).and_call_original

        main.run
      end
    end

    it "ensures that needed packages are installed" do
      expect(Yast::PackageSystem).to receive(:CheckAndInstallPackages).with(["salt"])
        .and_return(true)
      main.run
    end

    context "when needed packages cannot be installed" do
      before do
        allow(Yast::PackageSystem).to receive(:CheckAndInstallPackages).and_return(false)
      end

      it "does not try to apply the configuration" do
        expect(provision).to_not receive(:run)
        main.run
      end
    end

    context "when the formulas configuration is not prepared correctly" do
      let(:prepared) { false }

      it "does not run the provisioner" do
        expect(provision).not_to receive(:run)

        main.run
      end
    end

    context "when the formulas configuration is prepared correctly" do
      it "runs the provisioner" do
        expect(provision).to receive(:run)
        main.run
      end
    end
  end
end
