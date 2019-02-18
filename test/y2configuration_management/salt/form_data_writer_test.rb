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
require "y2configuration_management/salt/form_data_writer"
require "y2configuration_management/salt/form_data"
require "y2configuration_management/salt/pillar"

describe Y2ConfigurationManagement::Salt::FormDataWriter do
  subject(:writer) { described_class.new(form, form_data) }

  let(:form_data) { Y2ConfigurationManagement::Salt::FormData.from_pillar(form, pillar) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(
      FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
    )
  end

  # FIXME: simplify test set up to not rely on an existing pillar
  let(:pillar) do
    Y2ConfigurationManagement::Salt::Pillar.from_file(
      FIXTURES_PATH.join("pillar", "test-formula.sls")
    )
  end

  describe "#to_pillar_data" do
    it "exports array collections as arrays" do
      computers = writer.to_pillar_data.dig("person", "computers")
      expect(computers).to contain_exactly(
        a_hash_including("brand" => "Dell"),
        a_hash_including("brand" => "Lenovo")
      )
    end

    it "exports hash based collections as hashes" do
      projects = writer.to_pillar_data.dig("person", "projects")
      expect(projects["yast2"]).to include("url" => "https://yast.opensuse.org")
    end

    it "exports scalar collections as arrays of scalar objects" do
      platforms = writer.to_pillar_data.dig("person", "projects", "yast2", "platforms")
      expect(platforms).to eq(["Linux"])
    end

    it "exports numbers as integer objects" do
      data = writer.to_pillar_data
      expect(data.dig("person", "siblings")).to eq(2)
    end

    it "exports dates as date objects" do
      data = writer.to_pillar_data
      expect(data.dig("person", "birth_date")).to be_a(Date)
    end

    it "exports datetimes as time objects" do
      data = writer.to_pillar_data
      expect(data.dig("person", "started_working_at")).to be_a(Time)
    end

    context "when the value is empty" do
      before do
        form_data.update(locator, "")
      end

      context "and it is optional" do
        let(:locator) { locator_from_string("root#person#email") }

        it "does not export the value" do
          data = writer.to_pillar_data
          expect(data.dig("person")).to_not have_key("email")
        end
      end

      context "and it mandatory" do
        let(:locator) { locator_from_string("root#person#name") }

        it "exports the value as 'null'" do
          data = writer.to_pillar_data
          expect(data.dig("person")).to have_key("name")
        end
      end

      context "and it fallback value was defined" do
        let(:locator) { locator_from_string("root#person#password") }

        it "exports the fallback value" do
          data = writer.to_pillar_data
          expect(data.to_h.dig("person", "password")).to eq("***")
        end
      end
    end
  end
end
