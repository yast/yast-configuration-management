#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2019] SUSE LLC
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
require "y2configuration_management/salt/form_data_reader"
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/pillar"

describe Y2ConfigurationManagement::Salt::FormDataReader do
  subject(:reader) { described_class.new(form, pillar) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(
      FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
    )
  end
  let(:pillar) do
    Y2ConfigurationManagement::Salt::Pillar.from_file(
      FIXTURES_PATH.join("pillar", "test-formula.sls")
    )
  end

  describe "#form_data" do
    context "when a value is defined in the pillar" do
      let(:locator) { locator_from_string("root#person#name") }

      it "uses the value from the pillar" do
        form_data = reader.form_data
        expect(form_data.get(locator)).to eq("Jane Doe")
      end
    end

    context "when a value is not defined in the pillar" do
      let(:locator) { locator_from_string("root#person#email") }

      it "uses the default value from the form definition" do
        form_data = reader.form_data
        expect(form_data.get(locator)).to eq("somebody@example.net")
      end
    end

    context "when a hash based collection is given" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "converts it to an array of hashes adding a '$key' key" do
        form_data = reader.form_data
        projects = form_data.get(locator)
        expect(projects).to be_a(Array)
        expect(projects[0]).to include("$key" => "yast2")
      end
    end

    context "when a simple hash based collection is given" do
      let(:locator) { locator_from_string("root#person#projects[0]#properties") }

      it "converts it to an array of hashes adding '$key' and '$value' keys" do
        form_data = reader.form_data
        expect(form_data.get(locator)).to eq(
          [
            { "$key" => "license", "$value" => "GPL-2.0-only" }
          ]
        )
      end
    end

    context "when a simple values based collection is given" do
      let(:locator) { locator_from_string("root#person#projects[0]#platforms") }

      it "keeps it as an array" do
        form_data = reader.form_data
        expect(form_data.get(locator)).to eq([{ "$value" => "Linux" }])
      end
    end

    context "when an array collection of hash values is given" do
      let(:locator) { locator_from_string("root#person#computers[0]#disks") }

      it "returns a plain array of plain hashes" do
        form_data = reader.form_data
        expected = [
          { "size" => "32GB", "type" => "SSD" },
          { "size" => "1TB", "type" => "HDD" }
        ]
        expect(form_data.get(locator)).to eq(expected)
      end
    end

    it "reads times as strings" do
      form_data = reader.form_data
      expect(form_data.get(locator_from_string("root#person#started_working_at")))
        .to be_a(String)
    end

    it "reads dates as strings" do
      form_data = reader.form_data
      expect(form_data.get(locator_from_string("root#person#birth_date")))
        .to be_a(String)
    end
  end
end
