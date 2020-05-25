# Copyright (c) [2020] SUSE LLC
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
require "y2configuration_management/salt/formulas_reader"

describe Y2ConfigurationManagement::Salt::FormulasReader do
  subject(:reader) do
    described_class.new(
      FIXTURES_PATH.join("formulas-ng"), FIXTURES_PATH.join("pillar")
    )
  end

  describe "#formulas" do
    it "returns all the formulas from the given path" do
      expect(reader.formulas.size).to eql(2)
    end

    context "when a formula does not contain a metadata file" do
      it "is returned anyway" do
        expect(reader.formulas.map(&:id)).to include("no-metadata")
      end
    end

    context "when a formula does not contain a form" do
      it "is skipped" do
        expect(reader.formulas.map(&:id)).to_not include("no-one")
      end
    end
  end
end
