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
require "y2configuration_management/salt/pillar"

describe Y2ConfigurationManagement::Salt::FormData do
  subject(:form_data) { described_class.from_pillar(form, pillar) }

  let(:form) do
    Y2ConfigurationManagement::Salt::Form.from_file(FIXTURES_PATH.join("form.yml"))
  end
  let(:pillar) { Y2ConfigurationManagement::Salt::Pillar.new(data: {}) }

  describe "#get" do
    context "when the value has not been set" do
      it "returns the default value" do
        expect(form_data.get(locator_from_string("root#person#name"))).to eq("John Doe")
      end

      context "and it is a collection" do
        it "returns an array with the default values" do
          expect(form_data.get(locator_from_string("root#person#computers")))
            .to eq([{ "brand" => "ACME", "disks" => [] }])
        end
      end
    end

    context "when the value has been set" do
      let(:locator) { locator_from_string("root#person#name") }

      before do
        form_data.update(locator, "Mr. Doe")
      end

      it "returns the already set value" do
        expect(form_data.get(locator)).to eq("Mr. Doe")
      end
    end

    context "when a collection locator and an index are given" do
      let(:locator) { locator_from_string("root#person#computers[0]") }

      it "returns the item in the given position" do
        expect(form_data.get(locator)).to eq("brand" => "ACME", "disks" => [])
      end
    end

    context "when a collection locator and a key are given" do
      let(:locator) { locator_from_string("root#person#projects[yast2]") }

      it "returns the item in the given position" do
        expect(form_data.get(locator))
          .to eq("$key" => "yast2", "url" => "https://yast.opensuse.org")
      end
    end

    context "when an index based collection locator is given" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "returns an array containing all the elements" do
        expect(form_data.get(locator)).to eq(
          [{ "$key" => "yast2", "url" => "https://yast.opensuse.org" }]
        )
      end
    end

    context "when a hash based collection locator is given" do
      let(:locator) { locator_from_string("root#person#computers") }

      it "returns an array containing all the elements" do
        expect(form_data.get(locator)).to eq(
          [{ "brand" => "ACME", "disks" => [] }]
        )
      end
    end
  end

  describe "#add_item" do
    let(:locator) { locator_from_string("root#person#computers") }

    it "adds the element to the collection" do
      form_data.add_item(locator, "brand" => "Dell", "disks" => 2)
      expect(form_data.get(locator.join(1))).to eq("brand" => "Dell", "disks" => 2)
    end

    context "when a hash based collection is referred" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "adds the element to the collection" do
        form_data.add_item(locator, "$key" => "openSUSE", "url" => "https://opensuse.org")
        expect(form_data.get(locator)).to eq(
          [
            { "$key" => "yast2", "url" => "https://yast.opensuse.org" },
            { "$key" => "openSUSE", "url" => "https://opensuse.org" }
          ]
        )
      end
    end
  end

  describe "#update_item" do
    let(:locator) { locator_from_string("root#person#computers[0]") }

    it "updates the item in the collection" do
      form_data.update_item(locator, "brand" => "Lenovo", "disks" => 3)
      expect(form_data.get(locator.parent)).to eq(
        [{ "brand" => "Lenovo", "disks" => 3 }]
      )
    end
  end

  describe "#remove_item" do
    it "removes the element from the collection" do
      form_data.remove_item(locator_from_string("root#person#computers[0]"))
      expect(form_data.get(locator_from_string("root#person#computers"))).to be_empty
    end
  end

  describe "#to_h" do
    it "exports array collections as arrays" do
      computers = form_data.to_h.dig("root", "person", "computers")
      expect(computers).to eq(
        [{ "brand" => "ACME", "disks" => [] }]
      )
    end

    it "exports hash based collections as hashes" do
      projects = form_data.to_h.dig("root", "person", "projects")
      expect(projects).to eq(
        "yast2" => { "url" => "https://yast.opensuse.org" }
      )
    end
  end

  describe "#copy" do
    it "returns a deep-copy of the object" do
      copy = form_data.copy
      # the copy looks the same
      expect(copy.to_h).to eq(form_data.to_h)
      # but *is* not the same at the top
      expect(copy).to_not be(form_data)
      # ... nor at a lower level
      locator = locator_from_string("root#person#name")
      malkovich = "John Malkovich"
      form_data.update_item(locator, malkovich)
      expect(copy.get(locator)).to_not eq(malkovich)
    end
  end
end
