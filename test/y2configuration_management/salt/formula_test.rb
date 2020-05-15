#!/usr/bin/env rspec
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
require "y2configuration_management/salt/formula"
require "y2configuration_management/salt/formulas_reader"

describe Y2ConfigurationManagement::Salt::Formula do
  subject(:formula) { described_class.new(path) }
  let(:path) { FIXTURES_PATH.join("formulas-ng", "test-formula") }

  describe "#description" do
    it "returns the formula description from the metadata" do
      expect(formula.description).to include("This is the description of the test formula")
    end

    context "when the formula does not have metadata" do
      let(:path) { FIXTURES_PATH.join("formulas-ng", "no-metadata") }

      it "returns an empty string" do
        expect(formula.description).to be_empty
      end
    end
  end

  describe "#write_pillar" do
    let(:pillar_path) { FIXTURES_PATH.join("pillar").join("test-formula.sls") }
    let(:pillar) { Y2ConfigurationManagement::Salt::Pillar.from_file(pillar_path) }

    it "returns false when it does not have a pillar associated" do
      expect(formula.write_pillar).to eql(false)
    end

    it "writes the pillar data" do
      formula.pillar = pillar
      expect(pillar).to receive(:save).and_return(true)
      expect(formula.write_pillar).to eql(true)
    end
  end
end
