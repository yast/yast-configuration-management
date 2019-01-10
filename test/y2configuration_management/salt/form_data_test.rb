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
require "y2configuration_management/salt/form_element_locator"

describe Y2ConfigurationManagement::Salt::FormData do
  subject(:form_data) { described_class.new(form) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end

  describe "#get" do
    context "when the value has not been set" do
      it "returns the default value" do
        expect(form_data.get(locator_from_string(".root.person.name"))).to eq("John Doe")
      end

      context "and it is a collection" do
        it "returns a hash with the default values" do
          expect(form_data.get(locator_from_string(".root.person.computers")))
            .to eq([{ "brand" => "ACME", "disks" => 1 }])
        end
      end
    end

    context "when the value has been set" do
      let(:locator) { locator_from_string(".root.person.name") }

      before do
        form_data.update(locator, "Mr. Doe")
      end

      it "returns the already set value" do
        expect(form_data.get(locator)).to eq("Mr. Doe")
      end
    end

    context "when a collection locator and an index is given" do
      let(:locator) { locator_from_string(".root.person.computers[0]") }

      it "returns the item in the given position" do
        expect(form_data.get(locator)).to eq("brand" => "ACME", "disks" => 1)
      end
    end
  end

  describe "#add" do
    let(:locator) { locator_from_string(".root.person.computers[1]") }

    it "adds the element to the collection" do
      form_data.add_item(locator.parent, "brand" => "Dell", "disks" => 2)
      expect(form_data.get(locator)).to eq("brand" => "Dell", "disks" => 2)
    end
  end

  describe "#update_item" do
    let(:locator) { locator_from_string(".root.person.computers[0]") }

    it "updates the item in the collection" do
      form_data.update_item(locator, "brand" => "Lenovo", "disks" => 3)
      expect(form_data.get(locator.parent)).to eq(
        [{ "brand" => "Lenovo", "disks" => 3 }]
      )
    end
  end

  describe "#remove_item" do
    it "removes the element from the collection" do
      form_data.remove_item(locator_from_string(".root.person.computers[0]"))
      expect(form_data.get(locator_from_string(".root.person.computers"))).to be_empty
    end
  end
end
