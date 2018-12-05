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

describe Y2ConfigurationManagement::Salt::Formula do
  let(:formulas) { described_class.all(FIXTURES_PATH.join("formulas-ng").to_s) }

  describe ".all" do
    it "returns all the formulas from the given path" do
      expect(formulas.size).to eql(2)
    end

    context "when a formula does not contain a metadata file" do
      it "is returned anyway" do
        expect(formulas.map(&:id)).to include("no-metadata")
      end
    end

    context "when a formula does not contain a form" do
      it "is skipped" do
        expect(formulas.map(&:id)).to_not include("no-one")
      end
    end

    context "when no path is given" do
      let(:formulas) { described_class.all }

      before do
        allow(described_class).to receive(:formula_directories)
          .and_return([FIXTURES_PATH.join("formulas-ng").to_s])
      end

      it "returns all the formulas from the default directories" do
        expect(formulas.size).to eql(2)
      end
    end
  end

  describe ".formula_directories" do
    let(:default_directories) do
      [described_class::FORMULA_BASE_DIR + "/metadata", described_class::FORMULA_CUSTOM_DIR]
    end

    it "returns an array with the default formula directories" do
      expect(described_class.formula_directories).to eql(default_directories)
    end
  end

  describe "#description" do
    it "returns the formula description from the metadata" do
      formula = formulas.find { |f| f.id == "test-formula" }
      expect(formula.description).to include("This is the description of the test formula")
    end

    context "when the formula does not have metadata" do
      it "returns an empty string" do
        formula = formulas.find { |f| f.id == "no-metadata" }
        expect(formula.description).to be_empty
      end
    end
  end
end
