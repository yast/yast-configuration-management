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
    let(:config) do
      { "configuration_management" =>  { "type" => "salt" } }
    end
    let(:filename) { "config.xml" }
    let(:file_exists?) { true }
    let(:provision) { instance_double(Yast::ConfigurationManagement::Clients::Provision) }
    let(:configurator) do
      instance_double(Yast::ConfigurationManagement::Configurators::Salt, prepare: true)
    end

    before do
      allow(Yast::WFM).to receive(:Args).with(0).and_return(filename)
      allow(Yast::XML).to receive(:XMLToYCPFile).with(filename).and_return(config)
      allow(Yast::ConfigurationManagement::Configurators::Base).to receive(:for)
        .and_return(configurator)
      allow(Yast::ConfigurationManagement::Clients::Provision).to receive(:new)
        .and_return(provision)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(filename).and_return(file_exists?)
    end

    it "runs the provisioner" do
      expect(provision).to receive(:run)
      main.run
    end

    context "when the configuration file is not found" do
      let(:file_exists?) { false }

      it "returns false" do
        expect(main.run).to eq(false)
      end
    end

    context "when no filename is given" do
      let(:filename) { nil }

      it "returns false" do
        expect(main.run).to eq(false)
      end
    end

    context "when no valid configuration is given" do
      let(:config) { nil }

      it "returns false" do
        expect(main.run).to eq(false)
      end
    end
  end
end
