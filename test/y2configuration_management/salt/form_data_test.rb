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
require "y2configuration_management/salt/form"
require "y2configuration_management/salt/form_data"

describe Y2ConfigurationManagement::Salt::FormData do
  subject(:form_data) { described_class.new(form) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end

  describe "#get" do
    context "when the value has not been set" do
      it "returns the default value" do
        expect(form_data.get(".root.person.name")).to eq("John Doe")
      end

      context "and it is a collection" do
        it "returns a hash with the default values" do
          expect(form_data.get(".root.person.computers"))
            .to eq([{ "brand" => "ACME", "disks" => 1 }])
        end
      end
    end

    context "when the value has been set" do
      before do
        form_data.update(".root.person.name", "Mr. Doe")
      end

      it "returns the already set value" do
        expect(form_data.get(".root.person.name")).to eq("Mr. Doe")
      end
    end
  end

  describe "#add" do
    it "adds the element to the collection" do
      form_data.add(".root.person.computers", "brand" => "Dell", "disks" => 2)
      expect(form_data.get(".root.person.computers")).to eq(
        [
          { "brand" => "ACME", "disks" => 1 },
          { "brand" => "Dell", "disks" => 2 }
        ]
      )
    end
  end

  describe "#remove" do
    it "removes the element from the collection" do
      form_data.remove(".root.person.computers", 0)
      expect(form_data.get(".root.person.computers")).to be_empty
    end
  end
end
