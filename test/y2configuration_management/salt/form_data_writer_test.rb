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
      computers = writer.to_pillar_data.dig("root", "person", "computers")
      expect(computers).to contain_exactly(
        a_hash_including("brand" => "Dell"),
        a_hash_including("brand" => "Lenovo")
      )
    end

    it "exports hash based collections as hashes" do
      projects = writer.to_pillar_data.dig("root", "person", "projects")
      expect(projects["yast2"]).to include("url" => "https://yast.opensuse.org")
    end

    it "exports scalar collections as arrays of scalar objects" do
      platforms = writer.to_pillar_data.dig("root", "person", "projects", "yast2", "platforms")
      expect(platforms).to eq(["Linux"])
    end
  end
end
