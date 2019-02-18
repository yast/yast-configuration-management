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
    Y2ConfigurationManagement::Salt::Form.from_file(
      FIXTURES_PATH.join("formulas-ng", "test-formula", "form.yml")
    )
  end
  let(:pillar_path) { FIXTURES_PATH.join("pillar").join("test-formula.sls") }
  let(:pillar) { Y2ConfigurationManagement::Salt::Pillar.from_file(pillar_path) }

  describe "#get" do
    context "when the locator refers to a scalar value" do
      it "returns the value" do
        name = form_data.get(locator_from_string("root#person#name"))
        expect(name.value).to eq("Jane Doe")
      end
    end

    context "when the locator refers to an index based collection locator is given" do
      it "returns a FormData instance containing the collection values" do
        computers = form_data.get(locator_from_string("root#person#computers"))
        expect(computers.value).to include(
          "brand" => "Dell", "disks" => [{ "size" => "1TB", "type" => "HDD" }]
        )
      end
    end

    context "when the locator refers to a hash based collection" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "returns an array containing all the elements" do
        projects = form_data.get(locator)
        expect(projects.value.first).to include(
          "$key" => "yast2", "url" => "https://yast.opensuse.org"
        )
      end
    end

    context "when a collection locator and an index are given" do
      let(:locator) { locator_from_string("root#person#computers[1]") }

      it "returns a FormData instance containing the element" do
        computer = form_data.get(locator)
        expect(computer.value).to eq(
          "brand" => "Dell", "disks" => [{ "size" => "1TB", "type" => "HDD" }]
        )
      end
    end

    context "when a collection locator and a key are given" do
      let(:locator) { locator_from_string("root#person#projects[yast2]") }

      it "returns the item in the given position" do
        project = form_data.get(locator)
        expect(project.value)
          .to include("$key" => "yast2", "url" => "https://yast.opensuse.org")
      end
    end

  end

  describe "#add_item" do
    let(:locator) { locator_from_string("root#person#computers") }

    it "adds the element to the collection" do
      form_data.add_item(locator, "brand" => "ACME")
      new_disk = form_data.get(locator.join(2))
      expect(new_disk.value).to eq("brand" => "ACME")
    end

    context "when a hash based collection is referred" do
      let(:locator) { locator_from_string("root#person#projects") }

      it "adds the element to the collection" do
        form_data.add_item(locator, "$key" => "openSUSE", "url" => "https://opensuse.org")
        expect(form_data.get(locator).value).to include(
          "$key" => "openSUSE", "url" => "https://opensuse.org"
        )
      end
    end
  end

  describe "#update_item" do
    let(:locator) { locator_from_string("root#person#computers[0]") }

    it "updates the item in the collection" do
      form_data.update_item(locator, "brand" => "ACME")
      expect(form_data.get(locator).value).to include("brand" => "ACME")
    end
  end

  describe "#remove_item" do
    it "removes the element from the collection" do
      form_data.remove_item(locator_from_string("root#person#computers[1]"))
      form_data.remove_item(locator_from_string("root#person#computers[0]"))
      expect(form_data.get(locator_from_string("root#person#computers"))).to be_empty
    end
  end

  describe "#copy" do
    it "returns a deep-copy of the object" do
      copy = form_data.copy
      # the copy looks the same
      expect(copy.value).to eq(form_data.value)
      # but *is* not the same at the top
      expect(copy).to_not be(form_data)
      # ... nor at a lower level
      locator = locator_from_string("root#person#name")
      malkovich = "John Malkovich"
      form_data.update_item(locator, malkovich)
      expect(copy.get(locator)).to_not eq(malkovich)
    end
  end

  describe "#merge" do
    subject(:form_data) do
      described_class.new("person" => { "name" => "John", "surname" => "Doe" })
    end

    let(:other_form_data) do
      described_class.new("person" => { "name" => "Jane" })
    end

    it "recursively merges the content" do
      merged = form_data.merge(other_form_data)
      expect(merged).to be_a(described_class)
      expect(merged.value).to eq(
        "person" => { "name" => "Jane", "surname" => "Doe" }
      )
    end
  end

  describe "#empty?" do
    context "when an empty instance is given" do
      subject(:form_data) { described_class.new({}) }

      it "returns true" do
        expect(form_data).to be_empty
      end
    end

    context "when an empty instance is given" do
      subject(:form_data) { described_class.new("name" => "Jane") }

      it "returns false" do
        expect(form_data).to_not be_empty
      end
    end

    context "when a scalar value is given" do
      subject(:form_data) { described_class.new("some-value") }

      it "returns false" do
        expect(form_data).to_not be_empty
      end
    end
  end

  describe "#size" do
    subject(:form_data) { described_class.new([{ "brand" => "ACME" }]) }

    it "returns the number of elements" do
      expect(form_data.size).to eq(1)
    end

    context "when an empty instance is given" do
      subject(:form_data) { described_class.new({}) }

      it "returns 0" do
        expect(form_data.size).to eq(0)
      end
    end

    context "when a scalar value is given" do
      subject(:form_data) { described_class.new("some-value") }

      it "returns 1" do
        expect(form_data.size).to eq(1)
      end
    end
  end

  describe "#first" do
    subject(:form_data) { described_class.new([{ "brand" => "ACME" }]) }

    it "returns first element" do
      expect(form_data.first.value).to eq("brand" => "ACME")
    end
  end
end
